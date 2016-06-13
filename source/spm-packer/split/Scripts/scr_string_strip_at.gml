repeat(argument2){argument0=string_delete(argument0, 1, string_pos(argument1, argument0))}
argument0=string_delete(argument0, string_pos(argument1, argument0), string_length(argument0))
return argument0
