{{/*
Expand the name of the chart.
*/}}
{{- define "chibisafe.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chibisafe.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "chibisafe.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chibisafe.labels" -}}
helm.sh/chart: {{ include "chibisafe.chart" . }}
{{ include "chibisafe.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chibisafe.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chibisafe.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chibisafe.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "chibisafe.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper storage class
*/}}
{{- define "chibisafe.storageClass" -}}
{{- $storageClass := .persistence.storageClass -}}
{{- if .global -}}
    {{- if .global.storageClass -}}
        {{- $storageClass = .global.storageClass -}}
    {{- end -}}
{{- end -}}
{{- if .persistence.storageClass -}}
    {{- $storageClass = .persistence.storageClass -}}
{{- end -}}
{{- if $storageClass -}}
    {{- if (eq "-" $storageClass) -}}
        {{- printf "storageClassName: \"\"" -}}
    {{- else -}}
        {{- printf "storageClassName: %s" $storageClass -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the database PVC name
*/}}
{{- define "chibisafe.databasePvcName" -}}
{{- if .Values.persistence.database.existingClaim }}
{{- .Values.persistence.database.existingClaim }}
{{- else }}
{{- printf "%s-database" (include "chibisafe.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Return the uploads PVC name
*/}}
{{- define "chibisafe.uploadsPvcName" -}}
{{- if .Values.persistence.uploads.existingClaim }}
{{- .Values.persistence.uploads.existingClaim }}
{{- else }}
{{- printf "%s-uploads" (include "chibisafe.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Return the logs PVC name
*/}}
{{- define "chibisafe.logsPvcName" -}}
{{- if .Values.persistence.logs.existingClaim }}
{{- .Values.persistence.logs.existingClaim }}
{{- else }}
{{- printf "%s-logs" (include "chibisafe.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Return the configmap name for Caddyfile
*/}}
{{- define "chibisafe.configMapName" -}}
{{- printf "%s-caddyfile" (include "chibisafe.fullname" .) }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "chibisafe.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}
