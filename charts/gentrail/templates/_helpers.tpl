{{/* Canonical name for a sub-component. */}}
{{- define "gentrail.name" -}}
{{- printf "gentrail-%s" .component -}}
{{- end -}}

{{/* Standard labels applied to every resource. */}}
{{- define "gentrail.labels" -}}
app.kubernetes.io/name: gentrail
app.kubernetes.io/component: {{ .component }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{/* Selector labels. */}}
{{- define "gentrail.selectorLabels" -}}
app.kubernetes.io/name: gentrail
app.kubernetes.io/component: {{ .component }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Image reference. */}}
{{- define "gentrail.image" -}}
{{- $reference := index (.Values.image.references | default dict) .component -}}
{{- if $reference -}}
{{- if not (regexMatch "^[^@[:space:]]+@sha256:[a-f0-9]{64}$" $reference) -}}
{{- fail "component image references must include a sha256 digest" -}}
{{- end -}}
{{ $reference }}
{{- else -}}
{{ .Values.image.registry }}/{{ .component }}:{{ .Values.image.tag }}
{{- end -}}
{{- end -}}

{{/* Pull-secret block (only emits imagePullSecrets if non-empty). */}}
{{- define "gentrail.imagePullSecrets" -}}
{{- if .Values.image.pullSecret -}}
imagePullSecrets:
  - name: {{ .Values.image.pullSecret }}
{{- end -}}
{{- end -}}

{{/* IRSA without the pod-identity webhook: a projected SA token (audience
     sts.amazonaws.com, signed by the cluster's OIDC issuer) plus the env the
     AWS SDK reads to call AssumeRoleWithWebIdentity. Pass the role ARN. */}}
{{- define "gentrail.irsaEnv" -}}
- name: AWS_ROLE_ARN
  value: {{ . | quote }}
- name: AWS_WEB_IDENTITY_TOKEN_FILE
  value: /var/run/secrets/eks.amazonaws.com/serviceaccount/token
{{- end -}}

{{- define "gentrail.irsaTokenMount" -}}
- name: aws-iam-token
  mountPath: /var/run/secrets/eks.amazonaws.com/serviceaccount
  readOnly: true
{{- end -}}

{{- define "gentrail.irsaTokenVolume" -}}
- name: aws-iam-token
  projected:
    sources:
      - serviceAccountToken:
          audience: sts.amazonaws.com
          expirationSeconds: 86400
          path: token
{{- end -}}

{{/* License delivered as a mounted secret so the kubelet propagates updates
     to running pods and the services hot-reload without a restart. */}}
{{- define "gentrail.licenseEnv" -}}
- name: LICENSE_JWT_FILE
  value: /etc/gentrail/license/jwt
{{- end }}

{{- define "gentrail.licenseMount" -}}
- name: license
  mountPath: /etc/gentrail/license
  readOnly: true
{{- end }}

{{- define "gentrail.licenseVolume" -}}
- name: license
  secret:
    secretName: {{ .Values.license.secretRef }}
{{- end }}

{{- define "gentrail.ruleStorageEnv" -}}
- name: RULES_DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: gentrail-rds-secret
      key: dsn
{{- end }}

{{- define "gentrail.traceStorageEnv" -}}
- name: TRACES_DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: gentrail-rds-secret
      key: dsn
{{- end }}
