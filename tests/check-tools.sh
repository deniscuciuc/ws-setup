#!/usr/bin/env bash
# Local-only functional checks; no cloud credentials or remote infrastructure.
set -euo pipefail
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
cd "$work"
cloudflared --version
skopeo --version
duf --version
nmap --version
iperf3 --version
printf 'project:\n  name: workstation\n' | yq -e '.project.name == "workstation"'
printf 'check:\n    @echo task-ran\n' >justfile
[[ $(just check) == task-ran ]]
cat >main.tf <<'EOF'
output "check" {
  value = "local-only"
}
EOF
tofu init -backend=false -input=false
tofu validate
tofu plan -input=false -out=plan
tofu show -json plan | jq -e '.planned_values.outputs.check.value == "local-only"'
if [[ ${1:-} == --devops ]]; then
  age-keygen -o key.txt
  recipient=$(age-keygen -y key.txt)
  printf 'example: local-test\n' >plain.yaml
  sops --encrypt --age "$recipient" plain.yaml >encrypted.yaml
  SOPS_AGE_KEY_FILE="$work/key.txt" sops --decrypt encrypted.yaml >restored.yaml
  cmp plain.yaml restored.yaml
  ansible localhost -i localhost, -c local -m ping
  trivy --version
fi
printf 'Tool behavior checks passed. Cloud access and live packet capture remain manual.\n'
