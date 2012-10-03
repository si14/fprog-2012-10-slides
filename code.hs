dispatch ref
         "vm_start"
         (ErlTuple [ErlBinary "user", ErlInt userId])
         inputV = do
    case fromErl inputV of
        Nothing -> return . Just $ toErl
            (Atom "error", ref, Just $ Atom "invalid_task")
        Just i -> do
            -- Process request
dispatch ref "vm_start" _user _input =
    return . Just $ toErl
        (Atom "error", ref, Just $ Atom "invalid_task")