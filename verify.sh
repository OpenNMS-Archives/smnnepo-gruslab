#! /bin/bash

# This script is used to verify the test lab setup. It executes smal test
# scripts located in the verify folder for each machine defined in the lab.
#
# The verify folder contains sub-folders, each building a test fixture. The name
# of the fixture (the folders name) must match the machines name as defined in
# the vagrant project. To match multiple machines, the fixtures name can contain
# wildcards (see bash globbing).
#
# Disclaimer: Theis script is carefully tailored with great giddines and without
# any responibility. It is not adaptable or reusabel in any way and will cause a
# lot of trubble, regardless if used in production or not.

# Check if CWD is a vagrant project
if [[ ! ( -e "Vagrantfile" && -d "verify" ) ]]; then
	echo "Current directory is not a vagrant project" >&2
	exit 1
fi

# Initialize stats
STAT_TOTAL_EXEC=0
STAT_TOTAL_FAIL=()

FAILED_TESTS=""

# Walk over all defined machines
while read VM VM_STATUS; do

	echo -e "\e[90m+- \e[39m${VM}"

	if [[ "${VM_STATUS}" != 'running' ]]; then
		echo -e "\e[90m| o- \e[39m\e[01m[\e[93m??\e[39m]\e[21m machine is not running: ${VM}"
		continue
	fi

	# Initialize stats
	STAT_SPECS_EXEC=0
	STAT_SPECS_FAIL=()

	# Find spec folders matching the VM name
	while read SPEC; do
		
		# Skip foler if folders name is not matchin VMs name
		if [[ ! ( "verify/${SPEC}" && "${VM}" == ${SPEC} ) ]]; then
			continue
		fi

		echo -e "\e[90m|  +- \e[39m${SPEC}"

		# Initialize stats
		STAT_TESTS_EXEC=0
		STAT_TESTS_FAIL=()
		
		# Find all tests in spec
		while read TEST; do
			echo -e -n "\e[90m|  |  o- \e[39m\e[01m[  ]\e[21m ${VM}/${SPEC}/${TEST}\r"
			
			# Update execution stats
			((STAT_TOTAL_EXEC++))
			((STAT_SPECS_EXEC++))
			((STAT_TESTS_EXEC++))

			# Execute the fixture
			OUTPUT=$(
				cat "verify/${SPEC}/${TEST}" \
				| vagrant ssh "${VM}" -c "/bin/bash" \
				2>&1
			)

			# Check result
			if [[ "${?}" -eq 0 ]]; then
				echo -e "\e[90m|  |  o- \e[39m\e[01m[\e[92m++\e[39m]\e[21m"

			else
				echo -e "\e[90m|  |  o- \e[39m\e[01m[\e[91m!!\e[39m]\e[21m"
				while read LINE; do
					echo -e "\e[90m|  |  |  \e[39m   :\e[91m ${LINE}\e[39m"
				done <<< "${OUTPUT}"
				
				# Update execution stats
				STAT_TOTAL_FAIL+=("${VM}/${SPEC}/${TEST}")
				STAT_SPECS_FAIL+=("${SPEC}/${TEST}")
				STAT_TESTS_FAIL+=("${TEST}")
			fi
		done < <(
			ls -1 "verify/${SPEC}/"
		)

		if [[ "${STAT_TESTS_EXEC}" -eq 0 ]]; then
			# Print warning if spac has no tests defined
			echo -e "\e[90m|  |  \\- \e[39m\e[01m[\e[93m??\e[39m]\e[21m No tests defined for spec"

		elif [[ "${#STAT_TESTS_FAIL[@]}" -gt 0 ]]; then
			# Print warning if some tests failed
			echo -e "\e[90m|  |  \\- \e[39m\e[01m[\e[91m!!\e[39m]\e[21m Some tests failed: ${#STAT_TESTS_FAIL[@]}/${STAT_TESTS_EXEC}"
		else

			echo -e "\e[90m|  |  \\- \e[39m\e[01m[\e[92m++\e[39m]\e[21m All test succeeded: ${STAT_TESTS_EXEC}"
		fi

	done < <(
		ls -1 "verify/"
	)

	if [[ "${STAT_SPECS_EXEC}" -eq 0 ]]; then
		# Print warning if no specs match the VM
		echo -e "\e[90m|  \\- \e[39m\e[01m[\e[93m??\e[39m]\e[21m No tests/specs defined for machine"

	elif [[ "${#STAT_SPECS_FAIL[@]}" -gt 0 ]]; then
		# Print warning if some tests failed
		echo -e "\e[90m|  \\- \e[39m\e[01m[\e[91m!!\e[39m]\e[21m Some tests failed: ${#STAT_SPECS_FAIL[@]}/${STAT_SPECS_EXEC}"

	else
		echo -e "\e[90m|  \\- \e[39m\e[01m[\e[92m++\e[39m]\e[21m All tests succeeded: ${STAT_SPECS_EXEC}"
	fi

done < <(
	vagrant status \
	| tail -n +3 \
	| head -n -4 \
	| tr -s ' ' \
	| cut -d ' ' -f 1-2
)

if [[ "${#STAT_SPECS_FAIL[@]}" -gt 0 ]]; then
	echo -e "\e[90m\\- \e[39m\e[01m[\e[91m!!\e[39m]\e[21m Some tests failed: ${#STAT_TOTAL_FAIL[@]}/${STAT_TOTAL_EXEC}"

	for FAIL in "${STAT_TOTAL_FAIL[@]}"; do
		echo -e "\e[90m   \e[39m   : \e[91m${FAIL}\e[39m"
	done

else
	echo -e "\e[90m\\- \e[39m\e[01m[\e[92m++\e[39m]\e[21m All tests succeeded: ${STAT_TOTAL_EXEC}"
fi
