# Opdracht: LAMP Stack

## Doel van deze opdracht
Het installeren van de LAMP-stack en het maken en uitvoeren van een PHP-bestand dat data uit een database haalt.

Hiervoor worden de volgende stappen uitgevoerd:
- Op CentOS 8 installeren van Apache, MariaDB en PHP
- Het aanmaken van de database “ICT” en tabel “Vakken” in MariaDB
- Het maken van een PHP-script om vakken op te halen en te tonen
- Het uitvoeren van het gemaakte PHP-script

Voor deze opdracht gaan we er vanuit dat je CentOS 8 geinstalleerd hebt in een Virtuele Machine, waarop je onderstaande commando's uitvoert.

## Log in als root

```su -```

We voeren hiermee alle hieronder volgende commando's uit onder de root user

## Systeem updaten

```sudo dnf update -y```

Krijg je de fout  _Errors during downloading metadata for repository 'appstream'_, dan wordt nog geen gebruik gemaakt van de nieuwe locatie voor repositories (in verband met _End of Life_ van CentOS 8). Voer dan onderstaande commando's uit:

- ```sudo sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo```

- ```sudo sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo```

Dit zorgt ervoor dat de CentOS mirrors worden geupdatet.
Voer daarna opnieuw het commando uit om het systeem te updaten.

## Apache installeren
Om Apache te installeren, installeren we de package _httpd_:

```sudo dnf install httpd -y```

Vervolgens schakelen we httpd in en starten deze direct:

```sudo systemctl enable --now httpd```

Als je nu op CentOS naar http://localhost gaat, dan verschijnt de standaard-pagina van Apache.

✅ Gelukt? Ga door naar de volgende stap!

❌ Niet gelukt? Vraag een medestudent om je te helpen. Lukt het dan nog niet? Vraag dan de docent

## MariaDB installeren
MariaDB is een alternatief voor MySQL. Om deze te installeren, installeren we de packages _mariadb-server_ en _mariadb_:

```sudo dnf install mariadb-server mariadb -y```

Vervolgens schakelen we mariadb in en starten deze direct:

```sudo systemctl enable --now mariadb```

Omdat we nu geen installatie op een productieserver doem, voeren we NIET de beveiligingsconfiguratie uit. Dit doe je normaal gesproken WEL:

```sudo mysql_secure_installation``` (niet uitvoeren)

## PHP installeren

Om PHP te installeren en gebruikt te kunnen maken van MySQL (MariaDB is compatible), installeren we de packages _php_ en _php_mysqlnd_:


```sudo dnf install php php-mysqlnd -y```

We herstarten Apache om PHP te activeren in Apache:

```sudo systemctl restart httpd```

### Testen of PHP werkt

Maak een testbestand aan door middel van het volgende commando:

```echo "<?php phpinfo(); ?>" > /var/www/html/info.php```

In dit PHP-script wordt de functie phpinfo() aangeroepen, die informatie geeft over de geinstalleerde PHP. Als je nu naar http://localhost/info.php gaat, dan wordt het script uitgevoerd en verschijnt een pagina met allerlei PHP informatie.

✅ Gelukt? Ga door naar de volgende stap!

❌ Niet gelukt? Vraag een medestudent om je te helpen. Lukt het dan nog niet? Vraag dan de docent

## Database en tabel aanmaken in MariaDB

We willen natuurlijk ook vanuit PHP gebruik maken van informatie die in de database is vastgelegd. Hiervoor maken we een database "ICT" aan met een tabel "Vakken". Dit doen we door de MariaDB SQL prompt aan te roepen:

```mysql```

En vervolgens het volgende SQL-script te plakken:

```sql
-- Stap 1: Maak de database aan
CREATE DATABASE IF NOT EXISTS ICT;
USE ICT;

-- Stap 2: Maak de tabel Vakken aan
CREATE TABLE IF NOT EXISTS Vakken (
    code VARCHAR(30) PRIMARY KEY,
    omschrijving TEXT,
    studiepunten INT
);

-- Stap 3: Voeg vakken toe
INSERT INTO Vakken (code, omschrijving, studiepunten) VALUES
('ENBO-ICT.A5.X.22', 'Webprogrammeren', 5),
('ENBO-OK.A2.X.21', 'Effectief lesgeven', 5),
('ENBO-ALT.A4.X.20', 'Pedagogisch Handelen', 5),
('ENBO-ALT.A4.X.21', 'Techniek in de praktijk A', 5),
('ENBO-ICT.C1.X.23', 'Datacommunicatie en Netwerken', 5),
('ENBO-SO.A1.X.21', 'Introductie in de dagelijkse praktijk van een docent', 5),
('ENBO-ICT.B6.X.21', 'Hardware & Besturingssystemen', 5),
('ENBO-OK.B2.X.21', 'Ontwikkeling, leren en motiveren', 5),
('ENBO-ICT.B5.X.22', 'Linux', 5),
('ENBO-SO.B1.X.22', 'De dagelijkse praktijk van een docent beroepsonderwijs', 10),
('ENBO-ALT.B4.X.20', 'Techniek in de praktijk B', 5),
('ENBO-OK.C2.X.21', 'Toetsing', 5),
('ENBO-OK.C3.X.21', 'Coachen in het beroepsonderwijs', 5),
('ENBO-ICT.C5.X.17', 'Object Georiënteerd programmeren', 10),
('ENBO-ICT.C4.X.23', 'Techniek in de praktijk C', 5),
('ENBO-SO.C1.X.23', 'Leren en opleiden voor een beroep: school en werkveld', 5),
('ENBO-ICT.C6.X.22', 'Server infrastructuur', 5),
('ENBO-SO.D1.X.23', 'Coachen van studenten en werken in een docententeam', 10),
('ENBO-OK.D2.X.21', 'Ouder- en ketencontact', 5),
('ENBO-ICT.D5.X.22', 'Security, Privacy en Ethiek', 5),
('ENBO-ICT.D4.X.23', 'Techniek in de praktijk D (security)', 5),
('ENBO-ALT.D6.X.15', 'Robotisering binnen de branche', 5),
('ENBO-SO.E1.X.23', 'De organisatie van het beroepsonderwijs', 10),
('ENBO-OK.E2.X.20', '(Vakinhoudelijke) profilering', 5),
('ENBO-ICT.E3.X.21', 'Python', 5),
('LROVO.PO.E4.X.15', 'Keuzemodule', 5),
('LROVO.PROF.E2.X.15', 'Profilering Beroep', 5),
('ENBO-ICT.E4.X.18', 'ICT & innovatie', 5),
('LROVO.ONV.X.22', 'Eindproduct onderzoekend vermogen', 10),
('LROVO.SLB.X.20', 'Leerverktraject. Startbekwaam docent in het beroepsonderwijs', 20);

```

Je krijgt na het uitvoeren een melding dat er 30 records zijn aangemaakt.  Sluit de MariaDB SQL prompt af met het commando

 ```EXIT;```

✅ Gelukt? Ga door naar de volgende stap!

❌ Niet gelukt? Vraag een medestudent om je te helpen. Lukt het dan nog niet? Vraag dan de docent

## PHP Script om data op de halen maken

Om de data op te halen die je zojuist in een databasetabel hebt gezet, gaan we een php-script maken. Hiervoor gebruiken we de teksteditor _nano_:

```nano /var/www/html/vakken.php```

Plak vervolgens het volgende PHP-script in de editor:

```php
<?php
// Databaseconfiguratie
$host = 'localhost';
$user = 'root';
$password = '';
$database = 'ICT';

// Verbind met de database
$conn = new mysqli($host, $user, $password, $database);

// Controleer de verbinding
if ($conn->connect_error) {
    die("Verbinding mislukt: " . $conn->connect_error);
}

// Haal alle vakken op
$sql = "SELECT code, omschrijving, studiepunten FROM Vakken ORDER BY code";
$result = $conn->query($sql);
?>

<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <title>Overzicht Vakken</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        th { background-color: #f4f4f4; }
    </style>
</head>
<body>
    <h1>Overzicht van Vakken</h1>

    <table>
        <thead>
            <tr>
                <th>Code</th>
                <th>Omschrijving</th>
                <th>Studiepunten</th>
            </tr>
        </thead>
        <tbody>
            <?php
            if ($result->num_rows > 0) {
                while ($row = $result->fetch_assoc()) {
                    echo "<tr>
                            <td>{$row['code']}</td>
                            <td>{$row['omschrijving']}</td>
                            <td>{$row['studiepunten']}</td>
                          </tr>";
                }
            } else {
                echo "<tr><td colspan='3'>Geen vakken gevonden.</td></tr>";
            }
            $conn->close();
            ?>
        </tbody>
    </table>
</body>
</html>

```

Sla het bestand op met <kbd>CTRL-X</kbd> en sluit nano af met <kbd>CTRL-X</kbd>

Roep vervolgens het bestand aan: http://localhost/vakken.php. Je zou nu een pagina moeten krijgen waarop alle ICT-vakken worden getoond in een nette tabel.

✅ Gelukt? Ga door naar de volgende stap!

❌ Niet gelukt? Vraag een medestudent om je te helpen. Lukt het dan nog niet? Vraag dan de docent

## 🎉🎉🎉 Gefeliciteerd 🎉🎉🎉

Je hebt een werkende LAMP-stack draaien op je CentOS 8!!

## Tijd over?
Voor bonuspunten 😉

Onderzoek dan:

- Wat er gedaan wordt in het SQL-script
- Of je (een beetje) kunt begrijpen wat er in het PHP-script gebeurt
- Wat gebeurt er als je ```sudo mysql_secure_installation``` uitvoert? Werkt het script dan nog? Wat zou er aangepast moeten worden?


