{{/*
Expand the name of the chart.
*/}}
{{- define "bulwark-mail.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "bulwark-mail.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label.
*/}}
{{- define "bulwark-mail.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "bulwark-mail.labels" -}}
helm.sh/chart: {{ include "bulwark-mail.chart" . }}
{{ include "bulwark-mail.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "bulwark-mail.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bulwark-mail.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "bulwark-mail.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "bulwark-mail.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Session Secret name.
*/}}
{{- define "bulwark-mail.sessionSecretName" -}}
{{- if .Values.session.existingSecret -}}
{{- .Values.session.existingSecret -}}
{{- else -}}
{{- printf "%s-session" (include "bulwark-mail.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{/*
PVC name for settings sync.
*/}}
{{- define "bulwark-mail.dataPvcName" -}}
{{- printf "%s-data" (include "bulwark-mail.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Whether settings sync uses a PVC. Only true when both settingsSync.enabled and
settingsSync.persistence.enabled are set, and the deployment is a single replica
(PVCs are RWO by default and can't be shared).
*/}}
{{- define "bulwark-mail.settingsSyncPvc" -}}
{{- if and .Values.settingsSync.enabled .Values.settingsSync.persistence.enabled -}}
true
{{- else -}}
false
{{- end -}}
{{- end }}
