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
  "readiness_assessment": {{
    "score_category": "<High|Medium|Low|Blocked>",
    "score_value": <integer | null>, // Optional numerical score 1-10
    "summary": "<Brief text summary of overall readiness, synthesizing info from code and platform docs>"
  }},
  "key_challenges": [
    // Include challenges identified from dependencies, Dockerfile, README, AND potential conflicts with platform docs
    {{
      "id": "<Unique ID string, e.g., CHAL-001>",
      "title": "<Concise title of the challenge>",
      "description": "<Detailed description of the challenge/risk>",
      "severity": "<High|Medium|Low>"
    }}
    // ... include other challenge objects
  ],
  "recommended_steps": [
    // Include steps relevant to code changes, configuration, and platform specifics
    {{
      "id": "<Unique ID string, e.g., STEP-001>",
      "title": "<Actionable title of the step>",
      "description": "<Details about the recommended step>",
      "priority": <integer> // Lower number means higher priority
    }}
    // ... include other step objects
  ],
  "technology_notes": [
    // Infer technologies from dependencies, Dockerfile, README
    "<Brief note about detected or inferred application technology/framework/language>"
    // ... include other relevant notes
  ],
  "documentation_notes": [
     // Summarize key aspects of the target platform based *only* on the uploaded documents
    "<Note summarizing relevant feature/constraint from uploaded platform documentation>"
    // ... include other relevant notes from platform docs
  ]
}}
