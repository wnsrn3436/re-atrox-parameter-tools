var i;
for(i=1; i<=string_length(argument1); i+=1)
{
    file_bin_write_byte(argument0, ord(string_copy(argument1, i, 1)))
}
repeat(argument2-string_length(argument1))
{
    file_bin_write_byte(argument0, 0)
}
