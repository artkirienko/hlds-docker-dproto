#include <amxmodx>

public plugin_init() {
	register_plugin( "Bind key", "1.0", "Arvy" )
	set_task(1.0, "setDefault", 0, "", 0, "b")
}

stock client_cmd_ex(id, const command[], any:...)
{
	if (id == 0 || is_user_connected(id))
	{
		new szMessage[256]

		format_args(szMessage, charsmax(szMessage), 1)

		message_begin(id == 0 ? MSG_ALL : MSG_ONE, 51, _, id)
		write_byte(strlen(szMessage) + 2)
		write_byte(10)
		write_string(szMessage)
		message_end()
	}
}

public setDefault() {
	client_cmd_ex(0, "bind ^"1^" ^"slot1^"")
	client_cmd_ex(0, "bind ^"2^" ^"slot2^"")
	client_cmd_ex(0, "bind ^"3^" ^"slot3^"")
	client_cmd_ex(0, "bind ^"4^" ^"slot4^"")
	client_cmd_ex(0, "bind ^"5^" ^"slot5^"")
	client_cmd_ex(0, "bind ^"6^" ^"slot6^"")
	client_cmd_ex(0, "bind ^"7^" ^"slot7^"")
	client_cmd_ex(0, "bind ^"8^" ^"slot8^"")
	client_cmd_ex(0, "bind ^"9^" ^"slot9^"")
	client_cmd_ex(0, "bind ^"0^" ^"slot10^"")
}
