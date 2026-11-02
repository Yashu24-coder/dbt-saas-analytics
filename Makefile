.PHONY: help install raw build test docs clean lineage

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install:      ## Install dbt and the local DuckDB adapter
	pip install -r requirements.txt
	dbt deps --profiles-dir .

raw:          ## Regenerate the raw CSV exports in data/raw
	python scripts/generate_seeds.py

build:        ## dbt build: models, snapshots and all tests
	dbt build --profiles-dir .

test:         ## Run only the tests
	dbt test --profiles-dir .

docs:         ## Generate and serve the dbt docs site
	dbt docs generate --profiles-dir . && dbt docs serve --profiles-dir .

lineage:      ## Redraw the lineage image in docs/images
	python scripts/render_lineage.py

clean:
	rm -rf target data/warehouse
