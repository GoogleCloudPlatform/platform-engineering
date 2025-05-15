# Migration Readiness Analysis Request

Analyze the readiness of an application for migration to the specified target platform. Base your analysis on the provided GitHub repository link, the **extracted repository content below**, and any **accompanying uploaded platform documents** (like PDFs, images, etc., if supplied directly).

**Target Platform:** {target_platform}
**GitHub Repository:** {github_repo_url}

---
**Extracted Repository Information:**

**README Content:**

**Dependency Files Content (e.g., requirements.txt, package.json, pom.xml):**

**Dockerfile Content:**

---

**Analysis Task:**

Evaluate the application's migration readiness by synthesizing information from all provided sources: the **repository details above (README, dependencies, Dockerfile)**, the general structure implied by the **GitHub repository link**, and the specifics of the target platform outlined in any **accompanying uploaded documents**.

Consider potential challenges, risks, necessary steps, and technology factors. Pay attention to dependencies listed and how they might align or conflict with the target platform described in the uploaded documentation. Note any containerization details from the Dockerfile.

**Output Format Instructions:**

**IMPORTANT:** Format your *entire* response as a single, valid JSON object. Do not include any text outside of the JSON structure (like introductory sentences or markdown formatting). The JSON object should strictly follow the structure outlined below:

```json
{{
  "$schema": "https://raw.githubusercontent.com/GoogleCloudPlatform/platform-engineering/refs/heads/migration-blocker-analysis/reference-architectures/gemini-powered-migration-blocker-analysis/schemas/report-template-v1.0.0-schema.json",
  "version": "0.0.1",
  "id": "migration-blocker-analysis-report-template-v0.0.1",
  "name": "Migration Blocker Analysis Report Template v0.0.1",
  "reportSections": [
    {{
      "name": "Executive Summary",
      "id": "section-exec-summary",
      "heading": "1. Executive Summary",
      "reportSubsections": [
        {{
          "name": "Overall Findings",
          "id": "subsection-overall-findings",
          "prompt": "Provide a high-level overview of the migration feasibility, key blockers identified, and recommended next steps based on the analyzed application.",
          "heading": "1.1. Overall Findings"
        }},
        {{
          "name": "Risk Assessment",
          "id": "subsection-risk-assessment",
          "prompt": "Summarize the primary risks associated with migrating the application and the potential impact of the identified blockers.",
          "heading": "1.2. Risk Assessment"
        }}
      ]
    }},
    {{
      "name": "Detailed Blocker Analysis",
      "id": "section-blocker-analysis",
      "heading": "2. Detailed Blocker Analysis",
      "reportSubsections": [
        {{
          "name": "Identified Blockers",
          "id": "subsection-identified-blockers",
          "prompt": "List and describe each specific technical or architectural blocker identified during the analysis. Include details on the components affected and the nature of the blocker.",
          "heading": "2.1. Identified Blockers"
        }},
        {{
          "name": "Effort Estimation",
          "id": "subsection-effort-estimation",
          "prompt": "Estimate the effort (e.g., in T-shirt sizes or story points) required to remediate each identified blocker.",
          "heading": "2.2. Remediation Effort Estimation"
        }},
        {{
          "name": "Remediation Suggestions",
          "id": "subsection-remediation-suggestions",
          "prompt": "Suggest potential solutions or workarounds for each identified blocker. Specify any tools, technology changes, or refactoring needed.",
          "heading": "2.3. Remediation Suggestions"
        }}
      ]
    }},
    {{
      "name": "Application Overview",
      "id": "section-app-overview",
      "heading": "3. Application Overview",
      "reportSubsections": [
        {{
          "name": "Architecture Summary",
          "id": "subsection-arch-summary",
          "prompt": "Briefly describe the application's architecture, key components, dependencies, and technologies used.",
          "heading": "3.1. Architecture Summary"
        }}
      ]
    }}
  ]
}}
