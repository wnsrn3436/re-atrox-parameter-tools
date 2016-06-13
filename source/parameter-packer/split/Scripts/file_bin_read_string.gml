var str, number;
str = ""
number = file_bin_read_byte(argument0)
while(number!=0)
{
    str += chr(number)
    number = file_bin_read_byte(argument0)
}
return str
