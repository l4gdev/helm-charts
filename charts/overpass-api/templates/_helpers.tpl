{{/*
Expand the name of the chart.
*/}}
{{- define "overpass-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "overpass-api.fullname" -}}
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
{{- define "overpass-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "overpass-api.labels" -}}
helm.sh/chart: {{ include "overpass-api.chart" . }}
{{ include "overpass-api.selectorLabels" . }}
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
{{- define "overpass-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "overpass-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "overpass-api.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "overpass-api.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the image name
*/}}
{{- define "overpass-api.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
Get the PVC name
*/}}
{{- define "overpass-api.pvcName" -}}
{{- if .Values.persistence.existingClaim }}
{{- .Values.persistence.existingClaim }}
{{- else }}
{{- include "overpass-api.fullname" . }}
{{- end }}
{{- end }}

{{/*
Get storage class name
*/}}
{{- define "overpass-api.storageClass" -}}
{{- if .Values.persistence.storageClass }}
{{- .Values.persistence.storageClass }}
{{- else if .Values.global.storageClass }}
{{- .Values.global.storageClass }}
{{- end }}
{{- end }}

{{/*
Calculate resource requests and limits based on preset
*/}}
{{- define "overpass-api.resources" -}}
{{- $preset := .Values.resources.preset -}}
{{- if eq $preset "micro" }}
requests:
  cpu: 1
  memory: 2Gi
limits:
  cpu: 2
  memory: 4Gi
{{- else if eq $preset "small" }}
requests:
  cpu: 2
  memory: 8Gi
limits:
  cpu: 4
  memory: 16Gi
{{- else if eq $preset "medium" }}
requests:
  cpu: 4
  memory: 16Gi
limits:
  cpu: 8
  memory: 32Gi
{{- else if eq $preset "large" }}
requests:
  cpu: 8
  memory: 32Gi
limits:
  cpu: 16
  memory: 64Gi
{{- else if eq $preset "xlarge" }}
requests:
  cpu: 16
  memory: 64Gi
limits:
  cpu: 32
  memory: 128Gi
{{- else if eq $preset "custom" }}
requests:
  cpu: {{ .Values.resources.requests.cpu }}
  memory: {{ .Values.resources.requests.memory }}
limits:
  cpu: {{ .Values.resources.limits.cpu }}
  memory: {{ .Values.resources.limits.memory }}
{{- end }}
{{- end }}

{{/*
Calculate storage size based on preset
*/}}
{{- define "overpass-api.storageSize" -}}
{{- if .Values.persistence.size }}
{{- .Values.persistence.size }}
{{- else }}
{{- $preset := .Values.resources.preset -}}
{{- if eq $preset "micro" }}10Gi
{{- else if eq $preset "small" }}50Gi
{{- else if eq $preset "medium" }}150Gi
{{- else if eq $preset "large" }}400Gi
{{- else if eq $preset "xlarge" }}1Ti
{{- else }}150Gi
{{- end }}
{{- end }}
{{- end }}

{{/*
ServiceMonitor namespace
*/}}
{{- define "overpass-api.serviceMonitor.namespace" -}}
{{- if .Values.monitoring.serviceMonitor.namespace }}
{{- .Values.monitoring.serviceMonitor.namespace }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}
