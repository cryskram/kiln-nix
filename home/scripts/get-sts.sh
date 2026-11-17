# Source and target profiles must differ: writing session creds into the source profile destroys its long-term key.
config="$HOME/.config/aws-sts.env"

[[ -n "${1:-}" ]] || { echo "Usage: get-sts <MFA_CODE>" >&2; exit 1; }
mfa_code="$1"

if [[ -f "$config" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$config"
  set +a
fi

: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID in $config}"
: "${AWS_MFA_USER:?Set AWS_MFA_USER in $config}"
: "${AWS_PROFILE:?Set AWS_PROFILE in $config}"
: "${AWS_CODEARTIFACT_DOMAIN:?Set AWS_CODEARTIFACT_DOMAIN in $config}"

source_profile="$AWS_PROFILE"
target_profile="${AWS_STS_TARGET_PROFILE:-default}"
unset AWS_PROFILE AWS_SESSION_TOKEN

mfa_device="arn:aws:iam::${AWS_ACCOUNT_ID}:mfa/${AWS_MFA_USER}"
domain="$AWS_CODEARTIFACT_DOMAIN"
domain_owner="${AWS_CODEARTIFACT_DOMAIN_OWNER:-$AWS_ACCOUNT_ID}"
region="${AWS_REGION:-ap-south-1}"

replace_key_hint() {
  echo "    aws configure set aws_access_key_id <KEY>        --profile $source_profile" >&2
  echo "    aws configure set aws_secret_access_key <SECRET> --profile $source_profile" >&2
}

src_key=$(aws configure get aws_access_key_id --profile "$source_profile" 2>/dev/null || true)
src_token=$(aws configure get aws_session_token --profile "$source_profile" 2>/dev/null || true)
if [[ -z "$src_key" ]]; then
  echo "✗ Profile '$source_profile' has no access key. Add a long-term IAM user key:" >&2
  replace_key_hint
  exit 1
fi
if [[ "$src_key" == ASIA* || -n "$src_token" ]]; then
  echo "✗ Profile '$source_profile' holds temporary session credentials; GetSessionToken needs a long-term key." >&2
  echo "  Remove its aws_session_token from ~/.aws/credentials, then:" >&2
  replace_key_hint
  exit 1
fi

echo "→ STS for $source_profile → $target_profile ..."
creds=$(aws sts get-session-token --duration-seconds 129600 --serial-number "$mfa_device" \
  --token-code "$mfa_code" --profile "$source_profile" --output json)

set_target() { aws configure set "$1" "$2" --profile "$target_profile"; }
set_target aws_access_key_id "$(jq -r .Credentials.AccessKeyId <<<"$creds")"
set_target aws_secret_access_key "$(jq -r .Credentials.SecretAccessKey <<<"$creds")"
set_target aws_session_token "$(jq -r .Credentials.SessionToken <<<"$creds")"
set_target region "$region"
echo "✅ STS credentials updated in [$target_profile] (36h)"

codeartifact=(--profile "$target_profile" --domain "$domain" --domain-owner "$domain_owner" --region "$region")
if token=$(aws codeartifact get-authorization-token "${codeartifact[@]}" --query authorizationToken --output text 2>/dev/null); then
  echo "✅ CodeArtifact token: ${token:0:12}..."
  echo "   export CODEARTIFACT_AUTH_TOKEN=$token"
  if aws codeartifact login --tool npm --repository npm-store "${codeartifact[@]}" >/dev/null 2>&1; then
    echo "✅ npm configured via codeartifact login (~/.npmrc, 12h)"
  else
    echo "⚠ CodeArtifact login failed (token still available via env export)"
  fi
else
  echo "⚠ STS ok, CodeArtifact failed (check aws config)"
fi

expiry=$(jq -r .Credentials.Expiration <<<"$creds")
echo "   Expires: $expiry"
notify-send "AWS STS" "Updated — expires $expiry" 2>/dev/null || true
