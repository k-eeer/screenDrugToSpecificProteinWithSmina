library(bio3d)


b <- read.pdb("3cm5")
a.inds <- atom.select(b, chain="A")
b.inds <- atom.select(b, chain="B")
bs <- binding.site(b, a.inds=a.inds, b.inds=b.inds, cutoff=2.5)
b$atom$b[ bs$inds$atom ] <- 1
b$atom$b[ -bs$inds$atom ] <- 0
print(bs$resnames)
