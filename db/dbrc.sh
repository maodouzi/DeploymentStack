function getSqlConn {
    local user=$1
    local passwd=$2
    local ipAddr=$3
    local dbName=$4
    local port=$5
    echo $(getSqlConn_${DB_TYPE} ${user} ${passwd} ${ipAddr} ${dbName} ${port})
}

function initDb {
    initDb_${DB_TYPE}    
}
