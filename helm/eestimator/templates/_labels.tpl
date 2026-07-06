{{- define "labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "{{ .Chart.AppVersion | replace "+" "-" }}"
app.kubernetes.io/component: frontend
app.kubernetes.io/part-of: Qpay-Online
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
monitoring_custom: "true"
{{- end -}}
