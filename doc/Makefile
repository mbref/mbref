all: png pdf

epsfiles = $(wildcard images/*.eps)
pngfiles = $(epsfiles:%.eps=%.png)

.PHONY : png
png: $(pngfiles)

%.png: %.eps
	convert -density 120 $< $@

xmlfiles = $(wildcard *.xml)
pdffiles = $(xmlfiles:%.xml=%.pdf) \
		s2imac_wm.pdf \
		s2imac_epc_ext.pdf \
		s2imac_epc.pdf

.PHONY : pdf
pdf: $(pdffiles)

%.pdf: %.xml
	docbook2pdf -o $(dir $@) $<

%.pdf: %.odt
	unoconv -l
	unoconv -v -f pdf $<

%.pdf: %.odg
	unoconv -l
	unoconv -v -f pdf $<

s2imac_epc.pdf: orig/xps_epc.pdf s2imac_epc_ext.pdf s2imac_wm.pdf
	@echo "$@     <--     $(word 1, $^) $(word 2, $^) $(word 3, $^)"
	@echo "[stage1]"
	@pdftk $(word 1, $^) background $(word 3, $^) output stage1.pdf verbose dont_ask
	@pdftk A=$(word 2, $^) B=stage1.pdf cat A B output stage2.pdf verbose dont_ask
	@rm -f stage1.pdf
	@echo "[stage2]"
	@echo "S2IMAC External Peripheral Controller (EPC) v1.02a/1,Black,notBold,notItalic,open,TopLeftZoom,25,485,0.0" >stage2.bm
	@jpdfbookmarks_cli $(word 2, $^) --dump | sed -e 's/^/	/' >>stage2.bm
	@cat $(patsubst %.pdf,%.bm,$(word 1, $^)) >>stage2.bm	
	@jpdfbookmarks_cli stage2.pdf --apply stage2.bm --force --out stage3.pdf
	@rm -f stage2.pdf stage2.bm
	@echo "[stage3]"
	@pdftk $(word 2, $^) dump_data | pdftk stage3.pdf update_info - output $@ verbose dont_ask
	@rm -f stage3.pdf

clean:
	rm -f $(pngfiles)
	rm -f $(pdffiles)
