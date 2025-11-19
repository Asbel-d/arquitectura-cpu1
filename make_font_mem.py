# make_font_mem.py
with open('font-terminus.asm') as f, open('font.mem','w') as out:
    for line in f:
        line=line.strip()
        if line.startswith('db'):
            b=line.split()[1].strip()
            # if like 00100100b  (binary)
            if b.endswith('b'):
                b=b[:-1]
                out.write("{:02x}\n".format(int(b,2)))
            else:
                # if decimal or hex, adapt parsing
                out.write("{:02x}\n".format(int(b,0)))