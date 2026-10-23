{{- define "gentrail.natsStorageGuard" -}}
{{- if not (has .storage (list "ephemeral" "persistent")) -}}
{{- fail "NATS storage must be ephemeral or persistent" -}}
{{- end -}}
{{- if .existing -}}
{{- $persistent := gt (len (default (list) .existing.spec.volumeClaimTemplates)) 0 -}}
{{- if ne $persistent (eq .storage "persistent") -}}
{{- fail "NATS storage changes require an explicit migration; the existing StatefulSet and volumes are preserved" -}}
{{- end -}}
{{- end -}}
{{- end -}}
