var str;
str = file_text_read_string(argument0)
str = string_copy(str, string_pos(" ", str), string_length(str))
while(string_copy(str, 1, 1)==" ")
{
    str = string_copy(str, 2, string_length(str))
}
file_text_readln(argument0)
return str
