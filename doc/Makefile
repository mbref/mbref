all: png pdf

epsfiles = $(wildcard images/*.eps)
pngfiles = $(epsfiles:%.eps=%.png)

.PHONY : png
png: $(pngfiles)

%.png: %.eps
	convert -density 120 $< $@

xmlfiles = $(wildcard *.xml)
pdffiles = $(xmlfiles:%.xml=%.pdf)

.PHONY : pdf
pdf: $(pdffiles)

%.pdf: %.xml
	docbook2pdf -o $(dir $@) $<

clean:
	rm -f $(pngfiles)
	rm -f $(pdffiles)
