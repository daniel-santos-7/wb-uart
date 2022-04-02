WORKDIR=work

RTL_SRC=$(wildcard ./rtl/*)
TBS_SRC=$(wildcard ./tbs/*)

GHDL=ghdl
GHDLFLAGS=--workdir=$(WORKDIR) --ieee=synopsys

$(WORKDIR):
	mkdir $@

$(WORKDIR)/work-obj93.cf: $(RTL_SRC) $(TBS_SRC) $(WORKDIR)
	$(GHDL) -i $(GHDLFLAGS) $(RTL_SRC) $(TBS_SRC)