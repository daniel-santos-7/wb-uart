# VHDL simulator
GHDL = ghdl
GHDLFLAGS = --workdir=$(WORKDIR) --ieee=synopsys
GHDLXOPTS = --ieee-asserts=disable --stop-time=10ms

WORKDIR  = work
WAVESDIR = waves
SYNDIR   = syn

# RTL files in dependency order
RTL_SRC = \
	./rtl/uart_pkg.vhdl \
	./rtl/fifo.vhdl \
	./rtl/uart_csrs.vhdl \
	./rtl/uart_rx.vhdl \
	./rtl/uart_tx.vhdl \
	./rtl/uart.vhdl \
	./rtl/uart_wbsl.vhdl

TBS_SRC = \
	./tbs/uart_tb_pkg.vhdl \
	./tbs/uart_tb.vhdl

TOP_TB    = uart_tb
TOP_SYNTH = uart_wbsl

$(WORKDIR) $(WAVESDIR) $(SYNDIR):
	@mkdir -p $@

.analyze: $(RTL_SRC) $(TBS_SRC) | $(WORKDIR)
	@$(GHDL) -a $(GHDLFLAGS) $(RTL_SRC) $(TBS_SRC)
	@touch $@

.make: .analyze
	@$(GHDL) -m $(GHDLFLAGS) $(TOP_TB)
	@touch $@

$(WAVESDIR)/$(TOP_TB).ghw: .make | $(WAVESDIR)
	@$(GHDL) -r $(GHDLFLAGS) $(TOP_TB) $(GHDLXOPTS) --wave=$@

.PHONY: simulation clean synthesis
simulation: .make
	@$(GHDL) -r $(GHDLFLAGS) $(TOP_TB) $(GHDLXOPTS)

synthesis: .analyze | $(SYNDIR)
	@$(GHDL) --synth $(GHDLFLAGS) --out=verilog $(TOP_SYNTH) > $(SYNDIR)/$(TOP_SYNTH).v

clean:
	@$(GHDL) clean --workdir=$(WORKDIR)
	@rm -rf .analyze .make $(WORKDIR) $(WAVESDIR) $(SYNDIR)
