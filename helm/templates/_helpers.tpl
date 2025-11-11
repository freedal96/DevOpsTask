{{- define "webapp.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "webapp.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}