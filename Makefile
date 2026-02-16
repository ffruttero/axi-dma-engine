# Default variables, can be overwritten:
SEED ?= 0
BATCH ?= 0
DEBUG ?= 0
COVER ?= 0
TEST ?= smoke

VSIM_EXTRA :=
VOPT_EXTRA :=

#Tool commands:
VLOG ?= vlog
VLIB ?= vlib

ifeq ($(BATCH),1)
  VSIM_EXTRA += -c -batch -do "run -all; quit -f"
else
  VSIM_EXTRA += -gui
endif

ifeq ($(COVER),1)
  VOPT_EXTRA += +cover=bcest+/dma_top.
  VSIM_EXTRA += -coverage
endif

ifeq ($(DEBUG),1)
  VOPT_EXTRA += -debug
endif


# Repo root (directory where this Makefile lives)
DMA_ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))


# Directories:
OUT 			:= $(DMA_ROOT)/libraries/out
QOUT			:= $(OUT)/questa
QWORK			:= $(OUT)/work
QLOG			:= $(OUT)/logs
QWAVES			:= $(OUT)/waves
RTL_FILELIST	:= $(DMA_ROOT)/libraries/vlog_rtl.f


.PHONY: hello help dirs comp elab sim clean

help:
	@echo "Available targets:"
	@echo "  make hello"
	@echo "  make comp"
	@echo "  make elab"
	@echo "  make sim"
	@echo "  make clean"

hello:
	@echo "Hello DMA project"

dirs:
	@mkdir -p $(QWORK)
	@mkdir -p $(QLOG)
	@mkdir -p $(QWAVES)

comp: dirs
	@if [ ! -d "$(QWORK)" ]; then \
		$(VLIB) $(QWORK); \
	fi
	@echo "DMA_ROOT = $(DMA_ROOT)"
	@echo "[COMP] Compiling RTL"
	$(VLOG) -sv -work $(QWORK) -f $(RTL_FILELIST) \
		> $(QLOG)/vlog.log 2>$(QLOG)/vlog.log || \
		( echo "[FAIL] See $(QLOG)/vlog.log"; exit 1 )

	@echo "[PASS] RTL compilation complete"


elab:
	@echo "Elaborating design..."
	vopt dma_top +acc -o dma_top_vopt -work $(QWORK) $(VOPT_EXTRA) \
		> $(QLOG)/vopt.log 2> $(QLOG)/vopt.log || \
		( echo "[FAIL] See $(QLOG)/vopt.log"; exit 1 )

	@echo "[PASS] RTL elaboration complete"

sim:
	@echo "[SIM] TEST=$(TEST) SEED=$(SEED) BATCH=$(BATCH) DEBUG=$(DEBUG) WAVES=$(WAVES)"
	vsim dma_top_vopt $(VSIM_EXTRA) -lib $(QWORK) \
    > $(QLOG)/vsim.log 2> $(QLOG)/vsim.log || \
		( echo "[FAIL] See $(QLOG)/vsim.log"; exit 1 )
	@echo "[PASS] RTL simulation complete"

clean:
	@echo "Cleaning..."
	@rm -rf out
