
# use R to nma
library(bio3d)
pdb <- read.pdb("3cm5")
pdb <- trim(pdb, "notwater")
# m.aa <- aanma(pdb, outmodes="noh")
# calpha
# m.noh <- aanma(pdb, outmodes="noh")
modes <- nma(pdb, ff="calpha")
print(modes)
# m.rr  <- aanma(pdb, reduced=TRUE, rtb=TRUE,outmodes="protein")
mktrj(modes, mode=7)
# pdf('nmaflut.pdf')
png('nmaflut.png')
plot(modes, sse=pdb)
# dev.copy2pdf(file="mode7.pdf")
dev.copy(png,'nmaflut.png')

