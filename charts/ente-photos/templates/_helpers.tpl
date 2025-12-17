{{/*
Expand the name of the chart.
*/}}
{{- define "ente-photos.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ente-photos.fullname" -}}
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
{{- define "ente-photos.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ente-photos.labels" -}}
helm.sh/chart: {{ include "ente-photos.chart" . }}
{{ include "ente-photos.selectorLabels" . }}
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
{{- define "ente-photos.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ente-photos.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Museum labels
*/}}
{{- define "ente-photos.museum.labels" -}}
{{ include "ente-photos.labels" . }}
app.kubernetes.io/component: museum
{{- end }}

{{/*
Museum selector labels
*/}}
{{- define "ente-photos.museum.selectorLabels" -}}
{{ include "ente-photos.selectorLabels" . }}
app.kubernetes.io/component: museum
{{- end }}

{{/*
Web component labels
*/}}
{{- define "ente-photos.web.labels" -}}
{{ include "ente-photos.labels" . }}
app.kubernetes.io/component: web-{{ .component }}
{{- end }}

{{/*
Web component selector labels
*/}}
{{- define "ente-photos.web.selectorLabels" -}}
{{ include "ente-photos.selectorLabels" . }}
app.kubernetes.io/component: web-{{ .component }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ente-photos.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ente-photos.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Museum fullname
*/}}
{{- define "ente-photos.museum.fullname" -}}
{{- printf "%s-museum" (include "ente-photos.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Web component fullname
*/}}
{{- define "ente-photos.web.fullname" -}}
{{- printf "%s-web-%s" (include "ente-photos.fullname" .) .component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
ConfigMap name for museum.yaml
*/}}
{{- define "ente-photos.museum.configMapName" -}}
{{- printf "%s-museum-config" (include "ente-photos.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Secret name for credentials
*/}}
{{- define "ente-photos.credentials.secretName" -}}
{{- if .Values.credentials.existingSecret }}
{{- .Values.credentials.existingSecret }}
{{- else }}
{{- printf "%s-credentials" (include "ente-photos.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
PostgreSQL host - handles both bundled and external
*/}}
{{- define "ente-photos.postgresql.host" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" .Release.Name }}
{{- else if .Values.externalDatabase.enabled }}
{{- .Values.externalDatabase.host }}
{{- else }}
{{- fail "Either postgresql.enabled or externalDatabase.enabled must be true" }}
{{- end }}
{{- end }}

{{/*
PostgreSQL port
*/}}
{{- define "ente-photos.postgresql.port" -}}
{{- if .Values.postgresql.enabled }}
{{- default 5432 .Values.postgresql.primary.service.ports.postgresql }}
{{- else }}
{{- default 5432 .Values.externalDatabase.port }}
{{- end }}
{{- end }}

{{/*
PostgreSQL database name
*/}}
{{- define "ente-photos.postgresql.database" -}}
{{- if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.database }}
{{- else }}
{{- .Values.externalDatabase.database }}
{{- end }}
{{- end }}

{{/*
PostgreSQL username
*/}}
{{- define "ente-photos.postgresql.username" -}}
{{- if .Values.postgresql.enabled }}
{{- .Values.postgresql.auth.username }}
{{- else }}
{{- .Values.externalDatabase.user }}
{{- end }}
{{- end }}

{{/*
PostgreSQL secret name
*/}}
{{- define "ente-photos.postgresql.secretName" -}}
{{- if .Values.postgresql.enabled }}
{{- if .Values.postgresql.auth.existingSecret }}
{{- .Values.postgresql.auth.existingSecret }}
{{- else }}
{{- printf "%s-postgresql" .Release.Name }}
{{- end }}
{{- else if .Values.externalDatabase.existingSecret.enabled }}
{{- .Values.externalDatabase.existingSecret.secretName }}
{{- else }}
{{- include "ente-photos.credentials.secretName" . }}
{{- end }}
{{- end }}

{{/*
PostgreSQL password key in secret
*/}}
{{- define "ente-photos.postgresql.passwordKey" -}}
{{- if .Values.postgresql.enabled }}
{{- default "password" .Values.postgresql.auth.secretKeys.userPasswordKey }}
{{- else if .Values.externalDatabase.existingSecret.enabled }}
{{- .Values.externalDatabase.existingSecret.passwordKey }}
{{- else }}
{{- "db-password" }}
{{- end }}
{{- end }}

{{/*
Generate random string for secrets
*/}}
{{- define "ente-photos.randomString" -}}
{{- randAlphaNum 32 }}
{{- end }}

{{/*
Museum API URL for web frontends
*/}}
{{- define "ente-photos.museum.apiUrl" -}}
{{- if .Values.museum.ingress.enabled }}
{{- $host := (index .Values.museum.ingress.hosts 0).host }}
{{- if .Values.museum.ingress.tls }}
{{- printf "https://%s" $host }}
{{- else }}
{{- printf "http://%s" $host }}
{{- end }}
{{- else }}
{{- printf "http://%s:%d" (include "ente-photos.museum.fullname" .) (int .Values.museum.service.port) }}
{{- end }}
{{- end }}

{{/*
Web component ConfigMap name
*/}}
{{- define "ente-photos.web.configMapName" -}}
{{- printf "%s-web-%s-config" (include "ente-photos.fullname" .) .component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Photos web app URL
*/}}
{{- define "ente-photos.web.photosUrl" -}}
{{- if and .Values.web.photos.enabled .Values.web.photos.ingress.enabled }}
{{- $host := (index .Values.web.photos.ingress.hosts 0).host }}
{{- if .Values.web.photos.ingress.tls }}
{{- printf "https://%s" $host }}
{{- else }}
{{- printf "http://%s" $host }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Albums/Share web app URL
*/}}
{{- define "ente-photos.web.albumsUrl" -}}
{{- if and .Values.web.share.enabled .Values.web.share.ingress.enabled }}
{{- $host := (index .Values.web.share.ingress.hosts 0).host }}
{{- if .Values.web.share.ingress.tls }}
{{- printf "https://%s" $host }}
{{- else }}
{{- printf "http://%s" $host }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Accounts web app URL
*/}}
{{- define "ente-photos.web.accountsUrl" -}}
{{- if and .Values.web.accounts.enabled .Values.web.accounts.ingress.enabled }}
{{- $host := (index .Values.web.accounts.ingress.hosts 0).host }}
{{- if .Values.web.accounts.ingress.tls }}
{{- printf "https://%s" $host }}
{{- else }}
{{- printf "http://%s" $host }}
{{- end }}
{{- end }}
{{- end }}
