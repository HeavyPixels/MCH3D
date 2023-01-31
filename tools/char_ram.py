display = \
    b"0123456789ABCDEF0123456789ABCDEF" \
    b"|                              |" \
    b"| This is a test of the char   |" \
    b"|         display mode.        |" \
    b"|                              |" \
    b"| THE QUICK BROWN FOX JUMPED   |" \
    b"|           OVER THE LAZY DOG. |" \
    b"|                              |" \
    b"| the quick brown fox jumped   |" \
    b"|           over the lazy dog. |" \
    b"|                              |" \
    b"| \x12\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x13 |" \
    b"| \x11                          \x11 |" \
    b"| \x14\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x10\x15 |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"|                              |" \
    b"\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B\x1B" \
    b"\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C\x1C" \
    b"\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D\x1D" \
    b"\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E\x1E" \
    b"\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F\x1F" \
    b"0123456789ABCDEF0123456789ABCDEF"

# r12, c4 - c27

with open("char_ram.hex", "w") as f:
    l = len(display)
    if l != 1024:
        print(f"Incorrect display length. Expected 1024, found {l}.")
    f.write(display.hex('\n'))