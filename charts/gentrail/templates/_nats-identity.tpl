{{- define "gentrail.natsMaterial" -}}
{{- if not (hasKey .Values "_natsMaterial") -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace "nats-server" -}}
{{- $material := dict -}}
{{- $revision := .Values.nats.credentialRevision | toString -}}
{{- if and $existing (eq (index ($existing.metadata.annotations | default dict) "gentrail.ai/credential-revision") $revision) -}}
{{- range $key, $value := $existing.data -}}
{{- if ne $key "nats.conf" -}}
{{- $_ := set $material $key ($value | b64dec) -}}
{{- end -}}
{{- end -}}
{{- else -}}
{{- $authority := genCA "gentrail-nats" 3650 -}}
{{- $names := list "nats" (printf "nats.%s.svc" .Release.Namespace) (printf "nats.%s.svc.cluster.local" .Release.Namespace) (printf "*.nats-headless.%s.svc" .Release.Namespace) (printf "*.nats-headless.%s.svc.cluster.local" .Release.Namespace) -}}
{{- $certificate := genSignedCert "nats" nil $names 365 $authority -}}
{{- $_ := set $material "ca.crt" $authority.Cert -}}
{{- $_ := set $material "server.crt" $certificate.Cert -}}
{{- $_ := set $material "server.key" $certificate.Key -}}
{{- range $role := list "authproxy" "evaluator" "dashboard" "headless" "operator" "cluster" -}}
{{- $_ := set $material (printf "%s.password" $role) (randAlphaNum 64) -}}
{{- end -}}
{{- end -}}
{{- range $key := list "ca.crt" "server.crt" "server.key" -}}
{{- $_ := required (printf "NATS material missing %s" $key) (index $material $key) -}}
{{- end -}}
{{- range $role := list "authproxy" "evaluator" "dashboard" "headless" "operator" "cluster" -}}
{{- $password := required (printf "NATS material missing %s identity" $role) (index $material (printf "%s.password" $role)) -}}
{{- if or (lt (len $password) 32) (gt (len $password) 256) -}}
{{- fail "NATS credential length invalid" -}}
{{- end -}}
{{- end -}}
{{- $_ := set .Values "_natsMaterial" $material -}}
{{- end -}}
{{- toJson .Values._natsMaterial -}}
{{- end -}}

{{- define "gentrail.natsClientEnv" -}}
- name: NATS_CREDENTIALS_FILE
  value: /var/run/gentrail/nats/client.json
- name: NATS_CA_FILE
  value: /var/run/gentrail/nats/ca.crt
{{- end -}}

{{- define "gentrail.natsClientMount" -}}
- name: nats-identity
  mountPath: /var/run/gentrail/nats
  readOnly: true
{{- end -}}

{{- define "gentrail.natsClientVolume" -}}
- name: nats-identity
  secret:
    secretName: nats-{{ .role }}
    defaultMode: 0440
{{- end -}}

{{- define "gentrail.natsConfig" -}}
port: 4222
client_advertise: "nats:4222"
http: "127.0.0.1:8222"
max_payload: 1048576
tls {
  cert_file: /etc/nats/server.crt
  key_file: /etc/nats/server.key
  ca_file: /etc/nats/ca.crt
  timeout: 5
}
authorization {
  timeout: 5
  users: [
  {{- $material := include "gentrail.natsMaterial" . | fromJson }}
  {{- $permissions := required "NATS permissions file is required" (.Files.Get "files/nats-permissions.json") | mustFromJson }}
  {{- range $role := list "authproxy" "evaluator" "dashboard" "headless" "operator" }}
  {{- $policy := required (printf "NATS permissions missing for %s" $role) (index $permissions $role) }}
  {{- $_ := required "NATS publish permissions missing" $policy.publish }}
  {{- $_ := required "NATS subscribe permissions missing" $policy.subscribe }}
    {user: {{ $role | quote }}, password: {{ index $material (printf "%s.password" $role) | quote }}, permissions: {{ $policy | toRawJson }}},
  {{- end }}
  ]
}
jetstream {
  store_dir: /data
}
{{- if gt (int .Values.nats.replicas) 1 }}
cluster {
  name: gentrail
  port: 6222
  no_advertise: true
  authorization {
    user: cluster
    password: {{ index $material "cluster.password" | quote }}
  }
  tls {
    cert_file: /etc/nats/server.crt
    key_file: /etc/nats/server.key
    ca_file: /etc/nats/ca.crt
    verify: true
    timeout: 5
  }
  routes: [
  {{- range $i := until (int .Values.nats.replicas) }}
    {{ printf "nats://cluster:%s@nats-%d.nats-headless.%s.svc:6222" (index $material "cluster.password") $i $.Release.Namespace | quote }},
  {{- end }}
  ]
}
{{- end }}
{{- end -}}
