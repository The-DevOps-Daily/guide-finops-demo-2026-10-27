# Every AWS CLI command in the guide, run with no credentials: a command whose
# parameters parse stops at "Unable to locate credentials". Anything else fails.
must 'aws --version'
fails=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  out=$(env -i PATH="$PATH" HOME="$(mktemp -d)" AWS_DEFAULT_REGION=us-east-1 AWS_EC2_METADATA_DISABLED=true \
    bash -c "$line" 2>&1 </dev/null)
  if printf '%s' "$out" | grep -q 'Unable to locate credentials'; then
    echo "ok: ${line:0:100}"
  else
    echo "::error::did not reach the credentials check: $line"
    echo "$out"
    fails=$((fails + 1))
  fi
done < scripts/cli-commands.txt
echo "commands that failed to parse: $fails"
[ "$fails" -eq 0 ] || exit 1
