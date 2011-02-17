#
# MB-Ref make file
#
# (C) Copyright 2010
# Li-Pro.Net <www.li-pro.net>
# Stephan Linz <linz@li-pro.net>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#

VERSION = 2011
SUBVERSION = 01
EXTRAVERSION = -rc1

MBREF_NAME = mbref
MBREF_VERSION = $(VERSION).$(SUBVERSION)$(EXTRAVERSION)

MBREF_PKGNAME = $(MBREF_NAME)-$(MBREF_VERSION)
MBREF_PKGRTAG = v$(MBREF_VERSION)

all configure install help:
	@echo
	@echo "This is MB-References $(MBREF_VERSION)"
	@echo "----------------------------------------------------"
	@echo "There is nothing to configure, build or install."
	@echo "Please read the README file."
	@echo
	@echo

.PHONY : doc dist CHANGELOG
doc:
	make -C $@

dist:
	git archive --format=tar --prefix=$(MBREF_PKGNAME)/ \
		$(MBREF_PKGRTAG) | bzip2 -9 >$(MBREF_PKGNAME).tar.bz2

CHANGELOG:
	git log --no-merges master | \
		unexpand -a | sed -e 's/\s\s*$$//' > $@
