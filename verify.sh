#! /bin/bash

# This script is used to verify the test setup. It executes test scripts
# located in the verify folder for each machine defined in the lab.
#
# The verify folder contains sub-folders, each building a test fixture. The name
# of the fixture (the folders name) must match the machines name as defined in
# the vagrant project. To match multiple machines, the fixtures name can contain
# wildcards (see bash globbing).
#
# Disclaimer: This script is carefully tailored with great giddines and without
# any responsibility. It is not adaptable or reusabel in any way and will cause a
# lot of trouble, regardless if used in production or not.

# Check if CWD is a vagrant project
if [[ ! -e "Vagrantfile" ]]; then
	echo "Current directory is not a vagrant project" >&2
	exit 1
fi

# Check if tests base-folder is available
if [[ ! -d "verify"  ]]; then
	echo "Tests base-folder is missing: verify"
	exit 1
fi

# Parse command line arguments
if [[ "${#}" -gt 1 ]]; then
	echo "Too many arguments." >&2
	exit 1

elif [[ "${#}" -eq 1 ]]; then
	FILTER="${1}"

else
	FILTER="*"
fi

# Initialize stats
STAT_TOTAL_EXEC=0
STAT_TOTAL_FAIL=()

# Initialize list for collecting failed tests
FAILED_TESTS=""

# Walk over all defined machines
while read VM VM_STATUS; do
	if [[ "${VM}" != ${FILTER} ]]; then
		continue
	fi

	printf '\e[90m+--O \e[39m%s\n' "${VM}"

	# Fail fast if machine is not running
	if [[ "${VM_STATUS}" != 'running' ]]; then
		printf '\e[90m|  \\- \e[39m\e[01m<\e[93m??\e[39m>\e[21m machine is not running: %s\n' "${VM}"
		continue
	fi

	# Collect specs for current machine
	SPECS=()
	while read SPEC; do
		# Skip foler if folders name is not matchin VMs name
		if [[ "${VM}" != ${SPEC} ]]; then
			continue
		fi

		SPECS+=("${SPEC}")
	done < <(
		ls -1 "verify/"
	)

	# Fail fast if no spacs match the machines
	if [[ "${#SPECS[@]}" -eq 0 ]]; then
		# Print warning if no specs match the VM
		printf '\e[90m|  \\- \e[39m\e[01m<\e[93m??\e[39m>\e[21m No specs matching this machine\n'
		continue
	fi

	# Initialize stats
	STAT_SPECS_EXEC=0
	STAT_SPECS_FAIL=()

	# Find spec folders matching the VM name
	for SPEC in "${SPECS[@]}"; do

		printf '\e[90m|  +--O \e[39m%s\n' "${SPEC}"

		# Collect tests for current spec
		TESTS=()
		while read TEST; do
			TESTS+=("${TEST}")
		done < <(
			ls -1 "verify/${SPEC}/"
		)

		# Fail fast if spec has no tests
		if [[ "${#TESTS[@]}" -eq 0 ]]; then
			printf '\e[90m|  |  \\- \e[39m\e[01m<\e[93m??\e[39m>\e[21m No tests defined for spec\n'
			continue
		fi

		# Initialize stats
		STAT_TESTS_EXEC=0
		STAT_TESTS_FAIL=()
		
		# Find all tests in spec
		for TEST in "${TESTS[@]}"; do
			printf '\e[90m|  |  +- \e[39m\e[01m[  ]\e[21m %s\r' "${TEST}"
			
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
				printf '\e[90m|  |  +- \e[39m\e[01m[\e[92m++\e[39m]\e[21m\n'

			else
				printf '\e[90m|  |  +- \e[39m\e[01m[\e[91m!!\e[39m]\e[21m\n'
				while read LINE; do
					printf '\e[90m|  |  | \e[39m   :\e[91m %s\e[39m\n' "${LINE}"
				done <<< "${OUTPUT}"
				
				# Update execution stats
				STAT_TOTAL_FAIL+=("${VM}/${SPEC}/${TEST}")
				STAT_SPECS_FAIL+=("${SPEC}/${TEST}")
				STAT_TESTS_FAIL+=("${TEST}")
			fi
		done

		if [[ "${#STAT_TESTS_FAIL[@]}" -eq 0 ]]; then
			printf '\e[90m|  |  \\- \e[39m\e[01m<\e[92m++\e[39m>\e[21m All test succeeded: %d\n' "${STAT_TESTS_EXEC}"
		
		else
			# Print warning if some tests failed
			printf '\e[90m|  |  \\- \e[39m\e[01m<\e[91m!!\e[39m>\e[21m Some tests failed: %d/%d\n' "${#STAT_TESTS_FAIL[@]}" "${STAT_TESTS_EXEC}"
		fi

	done

	if [[ "${#STAT_SPECS_FAIL[@]}" -gt 0 ]]; then
		# Print warning if some tests failed
		printf '\e[90m|  \\- \e[39m\e[01m<\e[91m!!\e[39m>\e[21m Some tests failed: %d/%d\n' "${#STAT_SPECS_FAIL[@]}" "${STAT_SPECS_EXEC}"

	else
		printf '\e[90m|  \\- \e[39m\e[01m<\e[92m++\e[39m>\e[21m All tests succeeded: %d\n' "${STAT_SPECS_EXEC}"
	fi

done < <(
	vagrant status \
	| awk '
		NR > 4 + 2	{ print buffer[NR % 4] }
					{ buffer[NR % 4] = $1 " " $2 }
	'
)

if [[ "${#STAT_SPECS_FAIL[@]}" -gt 0 ]]; then
	printf '\e[90m\\- \e[39m\e[01m<\e[91m!!\e[39m>\e[21m Some tests failed: %d/%d\n' "${#STAT_TOTAL_FAIL[@]}" "${STAT_TOTAL_EXEC}"

	for FAIL in "${STAT_TOTAL_FAIL[@]}"; do
		printf '\e[90m   \e[39m   : \e[91m%s\e[39m\n' "${FAIL}"
	done

else
	printf '\e[90m\\- \e[39m\e[01m<\e[92m++\e[39m>\e[21m All tests succeeded: %d\n' "${STAT_TOTAL_EXEC}"
fi
