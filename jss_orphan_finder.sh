#!/bin/bash

CURRENT_DATE=$(date +"%d/%m/%y")
TITLE="JSS Orphan Report for $CURRENT_DATE"

read -p 'JSS Address: ' JSS_ADDRESS
read -p 'JSS Username: ' API_USERNAME 
read -sp 'Password: ' API_PASSWORD

JSS_ADDRESS="$JSS_ADDRESS/JSSResource"

all_policy_ids=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/policies | xpath /policies/policy/id | sed 's/<id>//g' | sed 's/<\/id>/ /g')

declare -a all_policy_ids_array=($all_policy_ids);
declare -a all_scoped_groups_id_array;
declare -a all_scoped_scripts_id_array;
declare -a all_scoped_packages_id_array;

declare -a no_site_array;
declare -a no_category_array;

declare -a unscoped_group_array;
declare -a unscoped_script_array;
declare -a unscoped_package_array;

if [ -s "$OUTPUTFILE" ]
then
	echo "Error: Output file already exists"
	exit
fi

function output_to_screen() {
barline="---------------"
    echo "$TITLE"
    echo "$barline$barline"
    if [[ ${#no_category_array[@]} > 0 ]]
    then
		echo "1. These policies are missing a category:" 
		echo "$barline"
		echo "Policy Name, ID" 
		echo "$barline"

		for policy_info in "${no_category_array[@]}" 
		do
			echo "$policy_info" 
		done
    else
    	echo "1. All policies have an assigned category." 
    fi
    
    echo " " 
    
    if [[ ${#no_site_array[@]} > 0 ]]
    then
		echo "2. These policies are not assigned to a JSS site:" 
		echo "$barline"
		echo "Policy Name, ID" 
    	echo "$barline"

		for policy_info in "${no_site_array[@]}" 
		do
			echo "$policy_info" 
		done
		
    else
    	echo "2. All policies have an assigned site." 
    fi
    
    echo " " 
    
    if [[ ${#unscoped_group_array[@]} > 0 ]]
    then
 		echo "3. There are ${#unscoped_group_array[@]} groups not being used in any policy scoping. Do you need them?" 
        echo "$barline"
		echo "Group Name, ID"
        echo "$barline"
 
		for group_info in "${unscoped_group_array[@]}" 
		do
			echo "$group_info" 
		done
    else
    	echo "3. All groups are scoped in one or more policies." 
    fi
    echo " " 
    
    if [[ ${#unscoped_script_array[@]} > 0 ]]
    then
   		echo "4. There are ${#unscoped_script_array[@]} scripts not being used in a policy. Do you need them?" 
		echo "$barline"
		echo "Script Name, ID" 
		echo "$barline"

		for script_info in "${unscoped_script_array[@]}" 
		do
			echo "$script_info" 
		done
    else
    	echo "4. All scripts are scoped in one or more policies." 
    fi
    echo " " 
    
    if [[ ${#unscoped_package_array[@]} > 0 ]]
    then
		echo "5. There are ${#unscoped_package_array[@]} packages not being used in a policy. Do you need them?" 
        echo "$barline"
		echo "Package Name, ID"
        echo "$barline"
 
		for pkg_info in "${unscoped_package_array[@]}" 
		do
			echo "$pkg_info" 
		done
    else
    	echo "5. All packages are scoped in one or more policies." 
    fi
    echo " " 
    
	echo "The end." 
       
}

function check_groups() {
	sorted_unique_ids=$(echo "${all_scoped_groups_id_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	all_group_ids=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/computergroups | xpath /computer_groups/computer_group/id | sed 's/<id>//g' | sed 's/<\/id>/ /g')
	declare -a all_group_ids_array=($all_group_ids);
	
	for group_id in "${all_group_ids_array[@]}" 
	do
		group_found="false"
		for scoped_group_id in "${all_scoped_groups_id_array[@]}"
		do
			if [[ "$group_id" == "$scoped_group_id" ]]
			then
				group_found="true"
				break
			fi
		done
		
		if [ "$group_found" == "false" ]
		then
			group_name=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/computergroups/id/"$group_id" | xpath /computer_group/name | sed 's/<name>//g' | sed 's/<\/name>/ /g')
   	    	group_info="$group_name, $group_id"
			unscoped_group_array=("${unscoped_group_array[@]}" "$group_info")
		fi
	done

}

function check_scripts() {
	sorted_unique_ids=$(echo "${all_scoped_scripts_id_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	all_script_ids=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/scripts | xpath /scripts/script/id | sed 's/<id>//g' | sed 's/<\/id>/ /g')
	declare -a all_script_ids_array=($all_script_ids);
	
	for script_id in "${all_script_ids_array[@]}" 
	do
		script_found="false"
		for scoped_script_id in "${all_scoped_scripts_id_array[@]}"
		do
			if [[ "$script_id" == "$scoped_script_id" ]]
			then
				script_found="true"
				break
			fi
		done
		
		if [ "$script_found" == "false" ]
		then
			script_name=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/scripts/id/"$script_id" | xpath /script/name | sed 's/<name>//g' | sed 's/<\/name>/ /g')
   	    	script_info="$script_name, $script_id"
			unscoped_script_array=("${unscoped_script_array[@]}" "$script_info")
		fi
	done

}

function check_packages() {
	sorted_unique_ids=$(echo "${all_scoped_packages_id_array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
	all_packages_ids=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/packages | xpath /packages/package/id | sed 's/<id>//g' | sed 's/<\/id>/ /g')
	declare -a all_packages_ids_array=($all_packages_ids);
	
	for pkg_id in "${all_packages_ids_array[@]}" 
	do
		pkg_found="false"
		for scoped_pkg_id in "${all_scoped_packages_id_array[@]}"
		do
			if [[ "$pkg_id" == "$scoped_pkg_id" ]]
			then
				pkg_found="true"
				break
			fi
		done
		
		if [ "$pkg_found" == "false" ]
		then
			pkg_name=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/packages/id/"$pkg_id" | xpath /package/name | sed 's/<name>//g' | sed 's/<\/name>/ /g')
   	    	pkg_info="$pkg_name, $pkg_id"
			unscoped_package_array=("${unscoped_package_array[@]}" "$pkg_info")
		fi
	done

}

function check_static_groups() {
	
	all_group_ids=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/computergroups)
	declare -a all_group_ids_array=($all_group_ids);
	
	for group_id in "${all_group_ids_array[@]}" 
	do
		group_found="false"
		for scoped_group_id in "${all_scoped_groups_id_array[@]}"
		do
			if [[ "$group_id" == "$scoped_group_id" ]]
			then
				group_found="true"
				break
			fi
		done
		
		if [ "$group_found" == "false" ]
		then
			group_name=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/computergroups/id/"$group_id" | xpath /computer_group/name | sed 's/<name>//g' | sed 's/<\/name>/ /g')
   	    	group_info="$group_name, $group_id"
			unscoped_group_array=("${unscoped_group_array[@]}" "$group_info")
		fi
	done
}

for id in "${all_policy_ids_array[@]}"
do
    policy_get=$(curl -k -u "$API_USERNAME":"$API_PASSWORD" "$JSS_ADDRESS"/policies/id/"$id")

    site=$(echo "$policy_get" | xpath /policy/general/site/id | sed -e 's/<id>//;s/<\/id>//')
    category=$(echo "$policy_get" | xpath /policy/general/category/id | sed -e 's/<id>//;s/<\/id>//')
	scoped_groups=$(echo "$policy_get" | xpath /policy/scope/computer_groups/computer_group/id | sed 's/<id>//g' | sed 's/<\/id>/ /g')
	scope_excluded_groups=$(echo "$policy_get" | xpath /policy/scope/exclusions/computer_groups/computer_group/id | sed 's/<id>//g' | sed 's/<\/id>/ /g')
	scoped_scripts=$(echo "$policy_get" | xpath /policy/scripts/script/id | sed 's/<id>//g' | sed 's/<\/id>/ /g')
	scoped_packages=$(echo "$policy_get" | xpath /policy/package_configuration/packages/package/id | sed 's/<id>//g' | sed 's/<\/id>/ /g')	
	
	declare -a scope_excluded_groups_array=($scope_excluded_groups);
	declare -a scoped_groups_id_array=($scoped_groups);
	declare -a scoped_scripts_id_array=($scoped_scripts);
	declare -a scoped_packages_id_array=($scoped_packages);

	all_scoped_scripts_id_array=( "${all_scoped_scripts_id_array[@]}" "${scoped_scripts_id_array[@]}" )
	all_scoped_packages_id_array=( "${all_scoped_packages_id_array[@]}" "${scoped_packages_id_array[@]}" )
	
	scoped_groups_id_array=( "${scoped_groups_id_array[@]}" "${scope_excluded_groups_array[@]}" )
	all_scoped_groups_id_array=( "${all_scoped_groups_id_array[@]}" "${scoped_groups_id_array[@]}" )
	

	if [ "$site" == "-1" ]
    then
    	policy_name=$(echo "$policy_get" | xpath /policy/general/name | sed -e 's/<name>//;s/<\/name>//')
		policy_info="$policy_name, $id"
    	no_site_array=("${no_site_array[@]}" "$policy_info")
    fi
    
    if [ "$category" == "-1" ]
    then
    	policy_name=$(echo "$policy_get" | xpath /policy/general/name | sed -e 's/<name>//;s/<\/name>//')
		policy_info="$policy_name, $id"
    	no_category_array=("${no_category_array[@]}" "$policy_info")
    fi    
done

check_groups
check_scripts
check_packages
output_to_screen