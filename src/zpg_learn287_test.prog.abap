*&---------------------------------------------------------------------*
*& Report ZPG_LEARN287_TEST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZPG_LEARN287_TEST.

types: begin of test,
  a type c,
  b type c,
  end of test.

data: g type test,
      h like g.
  g = value test( a = 'a'
                  b = 'b').

  Move-corresponding g to h.

data: zzz type i value 1.

do 5 times.
  check zzz < 5.
  zzz = zzz + 1.
  write zzz.


enddo.

write zzz.
