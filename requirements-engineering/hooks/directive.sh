#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
YOU_DECIDE="YOU DECIDE: 요구사항이 검증가능·일관·추적 가능하게 명세되었는가"
USE_WHEN="USE_WHEN: product 가설이 확정되어 정식 스펙으로 전환할 때"
PRODUCES="PRODUCES (required record fields): structured requirements doc, traceability matrix, ambiguity list resolved (each requirement: ID + statement + ears_pattern + verification_method + verification condition; matrix: ID + description + source + downstream_link + optional status; ambiguity: statement + candidate readings + resolution) / loop_state vocabulary: drafting, hypothesis-not-final, landed, resolving-ambiguity, source-unresolvable"
HAND_OFF="WRITE_SCOPE: [] (report-only role — no code/doc write outside the record itself) / HAND-OFF: 화면/플로우 설계는 → interaction-design"
core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
