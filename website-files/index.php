<?php
        $servername = "dbserver";
        $username = "tyme";
        $password = "welkom";
        $database = "test";

        // Create connection
        $conn = mysqli_connect($servername, $username, $password, $database);
        #mysqli_select_db('test');
        // Check connection
        if ($conn->connect_error) {
          die("Connection failed: " . $conn->connect_error);
        }
        #echo "Connected successfully";

        $sql = "SELECT * FROM user_details;";
        $result = $conn->query($sql);




        echo "<html>
        <head>
    
        </head>
        <body>
            <h1>webserver</h1>";

        echo "<table>"; // start a table tag in the HTML
        if ($result->num_rows > 0) {
            while($row = $result->fetch_assoc()){   //Creates a loop to loop through results
                echo "<tr>";
                echo "<td>" . htmlspecialchars($row['user_id']) . "</td>";
                echo "<td>" . htmlspecialchars($row['username']) . "</td>";
                echo "<td>" . htmlspecialchars($row['gender']) . "</td>";
                echo "</tr>";  //$row['index'] the index here is a field name
            }
        }

        echo "</table>"; //Close the table in HTML

        echo "   </body>
        </html>";
        ?>

 