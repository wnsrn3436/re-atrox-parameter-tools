var str, number;
str = ""
repeat(argument1)
{
    number = file_bin_read_byte(argument0)
    if(number!=0)
    {
        str += chr(number)
    }
}
return str
