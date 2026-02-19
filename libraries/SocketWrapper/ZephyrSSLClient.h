/*
 * Copyright (c) Arduino s.r.l. and/or its affiliated companies
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#pragma once

#include "SocketWrapper.h"
#include "api/Client.h"
#include "unistd.h"
#include "zephyr/sys/printk.h"
#include "ZephyrClient.h"

#if defined(CONFIG_NET_SOCKETS_SOCKOPT_TLS)
class ZephyrSSLClient : public ZephyrClient {

public:
	int connect(const char *host, uint16_t port) override {
		return connectSSL(host, port, nullptr);
	}

	int connect(const char *host, uint16_t port, const char *cert) {
		return connectSSL(host, port, cert);
	}
};
#endif
