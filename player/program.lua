while true do
    while cargo() < capacity() do
        move_to(nearest_ore())
        mine()
    end

    move_to("base")
    deposit()
end
