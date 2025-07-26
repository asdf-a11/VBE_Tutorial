import sys
from PIL import Image
import numpy
import numpy as np
for i in range(1,len(sys.argv)):
    pic = Image.open(sys.argv[i])
    pix = numpy.array(pic.getdata(),numpy.ubyte)
    name = sys.argv[i]
    name = name[:-1];name = name[:-1];name = name[:-1];name = name[:-1]
    f = open(name+".bin","wb")
    f.write(bytes(np.array([pic.size[0],pic.size[1]],np.uint)))
    f.write(bytes(pix.flatten()))
    f.close()