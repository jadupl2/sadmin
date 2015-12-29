#!/usr/bin/env sh
function sadm_display_menu()
{
    marray=( "$@" )                                                     # Save Array of menu recv.
    for i in "${marray[@]}" 
	do
        echo "$i"
  	done
    return
}

    menu_array=( 'Menu Item 1'  'Menu Item 2'  'Menu Item 3' )
    sadm_display_menu "${menu_array[@]}"

