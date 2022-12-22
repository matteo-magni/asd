#!/usr/bin/env bash

ZIP=$(mktemp)
WD=$(mktemp -d)
trap "rm -rf ${ZIP} ${WD}" EXIT

INPUTS='
[
    "a-value",
    "thisisareallysecretstring"
]
'

REPOSITORY=${REPOSITORY:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}
# echo "I want to fail"
# exit 1

pushd ${WD}

gh api -H "Accept: application/vnd.github+json" \
    /repos/${REPOSITORY}/actions/runs/${RUN_ID}/logs > ${ZIP}
unzip ${ZIP}

JOB_NAME="unmasked"
echo "Searching job '${JOB_NAME}'"
jq -r '.[]' <<<"${INPUTS}" | while read PLAINTEXT; do
    B64ENCODED=$(base64 <<<"${PLAINTEXT}")
    grep -R "${PLAINTEXT}" "${JOB_NAME}" || { echo "WARNING - String '${PLAINTEXT}' not found" ; exit 2 ; } || true
    grep -R "${B64ENCODED}" "${JOB_NAME}" || { echo "WARNING - String '${B64ENCODED}' not found" ; exit 2 ; } || true
done

echo

JOB_NAME="masked"
echo "Searching job '${JOB_NAME}'"
jq -r '.[]' <<<"${INPUTS}" | while read PLAINTEXT; do
    B64ENCODED=$(base64 <<<"${PLAINTEXT}")
    grep -R "${PLAINTEXT}" "${JOB_NAME}" && { echo "ERROR - String '${PLAINTEXT}' found" ; exit 1 ; } || echo "INFO - String '${PLAINTEXT}' not found"
    grep -R "${B64ENCODED}" "${JOB_NAME}" && { echo "ERROR - String '${B64ENCODED}' found" ; exit 1 ; } || echo "INFO - String '${B64ENCODED}' not found"
done

popd
