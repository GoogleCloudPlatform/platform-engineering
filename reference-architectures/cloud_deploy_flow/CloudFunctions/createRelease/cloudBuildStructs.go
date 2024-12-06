package example

// Define the struct to match the JSON structure
type GitSource struct {
	URL      string `json:"url"`
	Revision string `json:"revision"`
}

type Source struct {
	GitSource GitSource `json:"gitSource"`
}

type Step struct {
	Name string   `json:"name"`
	Args []string `json:"args"`
	Dir  string   `json:"dir"`
}

type SourceProvenance struct {
	ResolvedGitSource GitSource `json:"resolvedGitSource"`
}

type Pool struct {
	// Pool is an empty struct in the JSON, so no fields are needed here
}

type Options struct {
	SubstitutionOption   string `json:"substitutionOption"`
	Logging              string `json:"logging"`
	DynamicSubstitutions bool   `json:"dynamicSubstitutions"`
	Pool                 Pool   `json:"pool"`
}

type Substitutions struct {
	TriggerBuildConfigPath string `json:"TRIGGER_BUILD_CONFIG_PATH"`
	TriggerName            string `json:"TRIGGER_NAME"`
	RefName                string `json:"REF_NAME"`
	BranchName             string `json:"BRANCH_NAME"`
	RepoFullName           string `json:"REPO_FULL_NAME"`
	CommitSha              string `json:"COMMIT_SHA"`
	ShortSha               string `json:"SHORT_SHA"`
	RevisionID             string `json:"REVISION_ID"`
	RepoName               string `json:"REPO_NAME"`
	DeployGCS              string `json:"_DEPLOY_GCS"`
}

type Artifacts struct {
	Images []string `json:"images"`
}

type BuildMessage struct {
	ID               string           `json:"id"`
	Status           string           `json:"status"`
	Source           Source           `json:"source"`
	CreateTime       string           `json:"createTime"`
	Steps            []Step           `json:"steps"`
	Timeout          string           `json:"timeout"`
	Images           []string         `json:"images"`
	ProjectID        string           `json:"projectId"`
	SourceProvenance SourceProvenance `json:"sourceProvenance"`
	BuildTriggerID   string           `json:"buildTriggerId"`
	Options          Options          `json:"options"`
	LogUrl           string           `json:"logUrl"`
	Substitutions    Substitutions    `json:"substitutions"`
	Tags             []string         `json:"tags"`
	Artifacts        Artifacts        `json:"artifacts"`
	QueueTtl         string           `json:"queueTtl"`
	ServiceAccount   string           `json:"serviceAccount"`
	Name             string           `json:"name"`
}
