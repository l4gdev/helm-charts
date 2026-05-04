{{/*
Expand the name of the chart.
*/}}
{{- define "stalwart-mail-ha.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "stalwart-mail-ha.fullname" -}}
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
{{- define "stalwart-mail-ha.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "stalwart-mail-ha.labels" -}}
helm.sh/chart: {{ include "stalwart-mail-ha.chart" . }}
{{ include "stalwart-mail-ha.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: stalwart
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "stalwart-mail-ha.selectorLabels" -}}
app.kubernetes.io/name: {{ include "stalwart-mail-ha.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "stalwart-mail-ha.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "stalwart-mail-ha.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Resolved image reference, choosing the foundationdb variant automatically.
*/}}
{{- define "stalwart-mail-ha.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- $variant := .Values.image.variant -}}
{{- if and (not $variant) (eq .Values.dataStore.type "foundationdb") -}}
{{- $variant = "fdb" -}}
{{- end -}}
{{- if eq $variant "fdb" -}}
{{- printf "%s:%s-fdb" .Values.image.repository $tag -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Whether the workload needs a PVC. RocksDB and SQLite must persist /data;
postgres/mysql/foundationdb keep all state external.
*/}}
{{- define "stalwart-mail-ha.needsPersistence" -}}
{{- if eq .Values.dataStore.type "rocksdb" -}}
{{- ternary "true" "false" .Values.dataStore.rocksdb.persistence.enabled -}}
{{- else if eq .Values.dataStore.type "sqlite" -}}
{{- ternary "true" "false" .Values.dataStore.sqlite.persistence.enabled -}}
{{- else -}}
false
{{- end -}}
{{- end }}

{{/*
Render the Stalwart v0.16 config.json (data store only). Other backends are
configured at runtime through `stalwart-cli apply`.
*/}}
{{- define "stalwart-mail-ha.configJson" -}}
{{- $cfg := dict -}}
{{- if eq .Values.dataStore.type "postgres" -}}
  {{- $pg := .Values.dataStore.postgres -}}
  {{- $_ := set $cfg "@type" "PostgreSql" -}}
  {{- $_ := set $cfg "host" $pg.host -}}
  {{- $_ := set $cfg "port" (int $pg.port) -}}
  {{- $_ := set $cfg "database" $pg.database -}}
  {{- $_ := set $cfg "authUsername" $pg.username -}}
  {{- $_ := set $cfg "authSecret" (dict "@type" "EnvironmentVariable" "variableName" "STALWART_STORE_PG_PASSWORD") -}}
  {{- $_ := set $cfg "useTls" $pg.useTls -}}
  {{- $_ := set $cfg "timeout" (int $pg.timeout) -}}
{{- else if eq .Values.dataStore.type "mysql" -}}
  {{- $my := .Values.dataStore.mysql -}}
  {{- $_ := set $cfg "@type" "MySql" -}}
  {{- $_ := set $cfg "host" $my.host -}}
  {{- $_ := set $cfg "port" (int $my.port) -}}
  {{- $_ := set $cfg "database" $my.database -}}
  {{- $_ := set $cfg "authUsername" $my.username -}}
  {{- $_ := set $cfg "authSecret" (dict "@type" "EnvironmentVariable" "variableName" "STALWART_STORE_MYSQL_PASSWORD") -}}
  {{- $_ := set $cfg "maxAllowedPacket" (int $my.maxAllowedPacket) -}}
{{- else if eq .Values.dataStore.type "foundationdb" -}}
  {{- $fdb := .Values.dataStore.foundationdb -}}
  {{- $_ := set $cfg "@type" "FoundationDb" -}}
  {{- $_ := set $cfg "clusterFile" $fdb.clusterFile -}}
  {{- if $fdb.datacenterId -}}{{- $_ := set $cfg "datacenterId" $fdb.datacenterId -}}{{- end -}}
  {{- $_ := set $cfg "transactionTimeout" (int $fdb.transactionTimeout) -}}
{{- else if eq .Values.dataStore.type "rocksdb" -}}
  {{- $rdb := .Values.dataStore.rocksdb -}}
  {{- $_ := set $cfg "@type" "RocksDb" -}}
  {{- $_ := set $cfg "path" $rdb.path -}}
  {{- $_ := set $cfg "blobSize" (int $rdb.blobSize) -}}
  {{- $_ := set $cfg "bufferSize" (int $rdb.bufferSize) -}}
  {{- $_ := set $cfg "poolWorkers" (int $rdb.poolWorkers) -}}
{{- else if eq .Values.dataStore.type "sqlite" -}}
  {{- $sq := .Values.dataStore.sqlite -}}
  {{- $_ := set $cfg "@type" "Sqlite" -}}
  {{- $_ := set $cfg "path" $sq.path -}}
  {{- $_ := set $cfg "poolMaxConnections" (int $sq.poolMaxConnections) -}}
  {{- $_ := set $cfg "poolWorkers" (int $sq.poolWorkers) -}}
{{- else -}}
  {{- fail (printf "dataStore.type %q is not one of postgres|mysql|foundationdb|rocksdb|sqlite" .Values.dataStore.type) -}}
{{- end -}}
{{- mustToPrettyJson $cfg -}}
{{- end }}

{{/*
List of enabled mail listeners as a slice of dicts, used by service-mail and
deployment templates to keep the port list in one place.
*/}}
{{- define "stalwart-mail-ha.mailListeners" -}}
{{- $items := list -}}
{{- range $name, $cfg := .Values.listeners -}}
  {{- if and $cfg.enabled (ne $name "http") -}}
    {{- $items = append $items (dict "name" $name "port" $cfg.port) -}}
  {{- end -}}
{{- end -}}
{{- toYaml $items -}}
{{- end }}

{{/*
ConfigMap name holding config.json.
*/}}
{{- define "stalwart-mail-ha.configMapName" -}}
{{- printf "%s-config" (include "stalwart-mail-ha.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}
