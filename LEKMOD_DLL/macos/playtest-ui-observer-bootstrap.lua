-- Use an independent context so observing city state never replaces the
-- standard or EUI city screen's own update/show handlers.
ContextPtr:LoadNewContext("LekmodTestObserver")
