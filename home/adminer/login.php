<?php
// Allows passwordless login for local dev
class AdminerLogin {
	function login($login, $password) {
		return true;
	}
}

return new AdminerLogin();
