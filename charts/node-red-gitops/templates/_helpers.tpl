{{/*
Generate resource name from instance name and release name.
If smart naming is enabled AND instance name equals release name, return just the name once.
Otherwise, return the concatenated name (legacy behavior).
Truncates to 63 characters (Kubernetes DNS label limit) with hash suffix for uniqueness.
Usage: {{ include "node-red-gitops.resourceName" . }}
Expects context with: $name, $.Release.Name, and $.Values (for naming.smart flag)
*/}}
{{- define "node-red-gitops.resourceName" -}}
{{- $name := "" -}}
{{- if and .Values.naming.smart (eq .name .Release.Name) -}}
{{- $name = .name -}}
{{- else -}}
{{- $name = printf "%s-%s" .name .Release.Name -}}
{{- end -}}
{{- if gt (len $name) 63 -}}
{{- $hash := sha256sum $name | trunc 8 -}}
{{- printf "%s-%s" (trunc 54 $name) $hash -}}
{{- else -}}
{{- $name -}}
{{- end -}}
{{- end -}}

{{/*
Generate full resource name with suffix (e.g., for secrets or loadbalancers)
Ensures total length stays within 63 character limit.
Usage: {{ include "node-red-gitops.secretName" . }}
Expects context with: $name, $.Release.Name, and $.Values (for naming.smart flag)
*/}}
{{- define "node-red-gitops.secretName" -}}
{{- $suffix := "-secret" -}}
{{- $maxBaseLen := sub 63 (len $suffix) | int -}}
{{- $fullName := "" -}}
{{- if and .Values.naming.smart (eq .name .Release.Name) -}}
{{- $fullName = .name -}}
{{- else -}}
{{- $fullName = printf "%s-%s" .name .Release.Name -}}
{{- end -}}
{{- if gt (len $fullName) $maxBaseLen -}}
{{- $hash := sha256sum $fullName | trunc 8 -}}
{{- $truncLen := sub $maxBaseLen 9 | int -}}
{{- printf "%s-%s%s" (trunc $truncLen $fullName) $hash $suffix -}}
{{- else -}}
{{- printf "%s%s" $fullName $suffix -}}
{{- end -}}
{{- end -}}

{{/*
Generate loadbalancer resource name
Ensures total length stays within 63 character limit.
Usage: {{ include "node-red-gitops.loadbalancerName" . }}
Expects context with: $name, $.Release.Name, and $.Values (for naming.smart flag)
*/}}
{{- define "node-red-gitops.loadbalancerName" -}}
{{- $suffix := "-loadbalancer" -}}
{{- $maxBaseLen := sub 63 (len $suffix) | int -}}
{{- $fullName := "" -}}
{{- if and .Values.naming.smart (eq .name .Release.Name) -}}
{{- $fullName = .name -}}
{{- else -}}
{{- $fullName = printf "%s-%s" .name .Release.Name -}}
{{- end -}}
{{- if gt (len $fullName) $maxBaseLen -}}
{{- $hash := sha256sum $fullName | trunc 8 -}}
{{- $truncLen := sub $maxBaseLen 9 | int -}}
{{- printf "%s-%s%s" (trunc $truncLen $fullName) $hash $suffix -}}
{{- else -}}
{{- printf "%s%s" $fullName $suffix -}}
{{- end -}}
{{- end -}}

{{/*
Generate ConfigMap resource name for vscode-setup
Ensures total length stays within 63 character limit.
Usage: {{ include "node-red-gitops.vscodeConfigMapName" . }}
Expects context with: $name, $.Release.Name, and $.Values (for naming.smart flag)
*/}}
{{- define "node-red-gitops.vscodeConfigMapName" -}}
{{- $suffix := "-vscode-setup" -}}
{{- $maxBaseLen := sub 63 (len $suffix) | int -}}
{{- $fullName := "" -}}
{{- if and .Values.naming.smart (eq .name .Release.Name) -}}
{{- $fullName = .name -}}
{{- else -}}
{{- $fullName = printf "%s-%s" .name .Release.Name -}}
{{- end -}}
{{- if gt (len $fullName) $maxBaseLen -}}
{{- $hash := sha256sum $fullName | trunc 8 -}}
{{- $truncLen := sub $maxBaseLen 9 | int -}}
{{- printf "%s-%s%s" (trunc $truncLen $fullName) $hash $suffix -}}
{{- else -}}
{{- printf "%s%s" $fullName $suffix -}}
{{- end -}}
{{- end -}}
