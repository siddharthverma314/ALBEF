# better make defaults - from https://tech.davis-hansson.com/p/make/
SHELL := bash
.ONESHELL:
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

ALL_DATASETS = coco vg sbu cc12m # cc3m_train cc3m_val

.PHONY:
all: $(ALL_DATASETS)

.PHONY:
$(ALL_DATASETS): %: %.json

cc12m_raw.json: cc12m.py
	base_dir=/datasets01/conceptual_captions/DownloadConceptualCaptions/
	python $< --out $@ --tsv $$base_dir/Train_GCC-training.tsv --imgdir $$base_dir/training


coco_raw.json: coco.jq
	COCO_DIR=/datasets01/coco
	jq \
	  --arg basedir "$$COCO_DIR/train2017" \
	  -f $< \
	  "$$COCO_DIR/annotations/captions_train2017.json" > $@

vg_raw.json: vg.jq
	VG_DIR=/datasets01/VisualGenome1.2/061517
	jq \
	  --arg basedir "$$VG_DIR/VG_100K_all" \
	  -f $< \
	  "$$VG_DIR/region_descriptions.json" > $@

sbu_raw.json: sbu.jq
	SBU_DIR=/fsx/lyuchen/vilt_dataset/sbu
	jq -Rs \
	  --arg basedir "$$SBU_DIR/images" \
	  -f $< \
	  "$$SBU_DIR/sbu_captions/vicente-flickr-1M-list-v2.txt" > $@

filter: filter.hs
	ghc $< -O3 --make -threaded

%.json: %_raw.json filter
	./filter $< $@ +RTS -N64
