#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# SAFE_RESPONDER.sh
# Vstup: text (stdin nebo jako argument)
# Výstup: JSON {classification:[], flags:{...}, response:"..."}

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BASE="$ROOT/dict/SEXUAL_SAFETY_BASE.yml"
PATTERNS="$ROOT/dict/SAFETY_PATTERNS.txt"

# read input
if [ $# -gt 0 ]; then
  INPUT="$*"
else
  INPUT="$(cat -)"
fi

# normalize
LOWER="$(printf '%s' "$INPUT" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')"

# simple fallback keyword lists (used if BASE missing)
biology_kw="reproductive reproduction pregnant pregnancy sperm egg fertility menstru period puberty hormone contraception"
relationships_kw="love relationship partner consent romantic dating intimacy respect"
adolescent_kw="how to am i is it normal puberty period wet dream"
explicit_kw="porn pornography nude sex sexual erotic fuck blowjob anal oral penetrat"
harmful_kw="exploit abuse rape incest child underage"

# if BASE exists, try to extract keywords lists (basic parsing)
if [ -f "$BASE" ]; then
  # extract lists using grep; tolerant to simple YAML shape
  extract_list() {
    local key="$1"
    awk "/^$key:/{flag=1;next} /^ *[a-z_]+:/{if(flag && \$0~/^[[:space:]]*-/) next} /^ *-/{if(flag) print \$0}" "$BASE" \
      | sed -E 's/^[[:space:]]*-[[:space:]]*"?(.*)"?/\1/' \
      | tr '\n' ' '
  }

  # try to find keys; fallback to defaults when empty
  b=$(extract_list "biology")
  r=$(extract_list "relationships")
  a=$(extract_list "adolescent_question")
  e=$(extract_list "explicit_attempt")
  h=$(extract_list "harmful")

  biology_kw="${b:-$biology_kw}"
  relationships_kw="${r:-$relationships_kw}"
  adolescent_kw="${a:-$adolescent_kw}"
  explicit_kw="${e:-$explicit_kw}"
  harmful_kw="${h:-$harmful_kw}"
fi

# helper to test any keyword presence (word boundary)
contains_any() {
  local text="$1"; shift
  for w in $*; do
    # escape possible regex-specials
    if printf '%s\n' "$text" | grep -Eiq "\\b$(printf '%s' "$w" | sed 's/[][.*^$()\\/]/\\&/g')\\b"; then
      return 0
    fi
  done
  return 1
}

# classification
declare -a classes
if contains_any "$LOWER" $harmful_kw; then
  classes+=("harmful")
fi
if contains_any "$LOWER" $explicit_kw; then
  classes+=("explicit_attempt")
fi
# biology should win if explicit absent
if contains_any "$LOWER" $biology_kw && ! contains_any "$LOWER" $explicit_kw; then
  classes+=("biology")
fi
if contains_any "$LOWER" $adolescent_kw; then
  classes+=("adolescent_question")
fi
if contains_any "$LOWER" $relationships_kw && ! contains_any "$LOWER" $explicit_kw; then
  classes+=("relationships")
fi

if [ "${#classes[@]}" -eq 0 ]; then
  classes+=("default")
fi

# flags default
allow_detail=false
must_generalize=false
must_redirect=false
reinforce_boundaries=false
suggest_help=false
provide_neutral_explanation=false
provide_reassurance=false
emphasize_consent=false
emphasize_respect=false
suggest_medical_sources=false
suggest_guardian_or_professional=false

# apply high-level rules (based on classes) - conservative prioritization
if printf '%s\n' "${classes[@]}" | grep -q -x "harmful"; then
  allow_detail=false
  must_generalize=true
  must_redirect=true
  reinforce_boundaries=true
  suggest_help=true
fi

if printf '%s\n' "${classes[@]}" | grep -q -x "explicit_attempt"; then
  allow_detail=false
  must_generalize=true
  must_redirect=true
  reinforce_boundaries=true
fi

if printf '%s\n' "${classes[@]}" | grep -q -x "biology"; then
  provide_neutral_explanation=true
  suggest_medical_sources=true
fi

if printf '%s\n' "${classes[@]}" | grep -q -x "adolescent_question"; then
  provide_reassurance=true
  suggest_guardian_or_professional=true
fi

if printf '%s\n' "${classes[@]}" | grep -q -x "relationships"; then
  allow_detail=true
  emphasize_consent=true
  emphasize_respect=true
fi

# choose a pattern response
pick_pattern_response() {
  local tag="$1"
  awk -v tag="### $tag" \
    'BEGIN{found=0}
     $0==tag{found=1; next}
     /^### / && found{exit}
     found{print}
    ' "$PATTERNS" | sed '/^[[:space:]]*$/d' | sed 's/^[[:space:]]*//'
}

RESP=""
# priority: harmful > explicit > adolescent > biology > relationships > default
if printf '%s\n' "${classes[@]}" | grep -q -x "harmful"; then
  RESP="$(pick_pattern_response "harmful")"
elif printf '%s\n' "${classes[@]}" | grep -q -x "explicit_attempt"; then
  RESP="$(pick_pattern_response "explicit_attempt")"
elif printf '%s\n' "${classes[@]}" | grep -q -x "adolescent_question"; then
  RESP="$(pick_pattern_response "adolescent_question")"
elif printf '%s\n' "${classes[@]}" | grep -q -x "biology"; then
  RESP="$(pick_pattern_response "biology")"
elif printf '%s\n' "${classes[@]}" | grep -q -x "relationships"; then
  RESP="$(pick_pattern_response "relationships")"
else
  RESP="$(pick_pattern_response "default")"
fi

# Augment response with small, safe extras
if [ "$provide_reassurance" = true ]; then
  RESP="$RESP\n\nPokud jsi mladý/á nebo znepokojený/á, je v pořádku mluvit o tom s důvěryhodným dospělým nebo zdravotníkem."
fi
if [ "$suggest_medical_sources" = true ]; then
  RESP="$RESP\n\nPro přesné zdravotní informace doporučuji vyhledat články zdravotních organizací nebo poradit se s lékařem."
fi
if [ "$suggest_help" = true ]; then
  RESP="$RESP\n\nV případě nouze kontaktuj místní tísňové linky nebo bezpečnostní služby."

# prepare JSON output
flags_json="$(jq -n \
  --argjson allow_detail "$allow_detail" \
  --argjson must_generalize "$must_generalize" \
  --argjson must_redirect "$must_redirect" \
  --argjson reinforce_boundaries "$reinforce_boundaries" \
  --argjson suggest_help "$suggest_help" \
  --argjson provide_neutral_explanation "$provide_neutral_explanation" \
  --argjson provide_reassurance "$provide_reassurance" \
  --argjson emphasize_consent "$emphasize_consent" \
  --argjson emphasize_respect "$emphasize_respect" \
  --argjson suggest_medical_sources "$suggest_medical_sources" \
  --argjson suggest_guardian_or_professional "$suggest_guardian_or_professional" \
  '{allow_detail:$allow_detail|false, must_generalize:$must_generalize|false, must_redirect:$must_redirect|false, reinforce_boundaries:$reinforce_boundaries|false, suggest_help:$suggest_help|false, provide_neutral_explanation:$provide_neutral_explanation|false, provide_reassurance:$provide_reassurance|false, emphasize_consent:$emphasize_consent|false, emphasize_respect:$emphasize_respect|false, suggest_medical_sources:$suggest_medical_sources|false, suggest_guardian_or_professional:$suggest_guardian_or_professional|false}')" || flags_json="{}"

# final JSON output (use jq if available, else rudimentary)
if command -v jq >/dev/null 2>&1; then
  jq -n --argjson classification "$(printf '%s\n' "${classes[@]}" | jq -R . | jq -s .)" \
        --arg flags "$flags_json" \
        --arg response "$RESP" \
        '{classification:$classification, flags:( $flags|fromjson ), response:$response }'
else
  # fallback plain output
  echo "classification: ${classes[*]}"
  echo "flags: $flags_json"
  echo -e "response:\n$RESP"
fi
