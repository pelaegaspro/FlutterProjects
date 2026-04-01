import '../models/models.dart';

class DemoDataService {
  static final List<FantasyMatch> matches = [
    FantasyMatch(
      id: 'demo-match-1',
      teamA: 'India',
      teamB: 'Australia',
      startTime: DateTime.now().add(const Duration(hours: 5)),
      venue: 'Wankhede Stadium',
      tournament: 'ODI Series',
    ),
    FantasyMatch(
      id: 'demo-match-2',
      teamA: 'Chennai',
      teamB: 'Mumbai',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
      venue: 'Chepauk',
      tournament: 'T20 League',
    ),
  ];

  static final Map<String, List<FantasyPlayer>> playersByMatch = {
    'demo-match-1': [
      _player('ind-1', 'Rohit Sharma', 'India', 'BAT', 10.5, 61, 58, 54),
      _player('ind-2', 'Shubman Gill', 'India', 'BAT', 9.5, 63, 52, 49),
      _player('ind-3', 'Virat Kohli', 'India', 'BAT', 10.5, 68, 60, 55),
      _player('ind-4', 'Shreyas Iyer', 'India', 'BAT', 8.5, 44, 47, 42),
      _player('ind-5', 'KL Rahul', 'India', 'WK', 8.5, 51, 48, 46),
      _player('ind-6', 'Rishabh Pant', 'India', 'WK', 9.0, 54, 46, 44),
      _player('ind-7', 'Hardik Pandya', 'India', 'AR', 9.5, 55, 51, 50),
      _player('ind-8', 'Ravindra Jadeja', 'India', 'AR', 9.0, 48, 49, 52),
      _player('ind-9', 'Axar Patel', 'India', 'AR', 8.0, 37, 41, 39),
      _player('ind-10', 'Jasprit Bumrah', 'India', 'BOWL', 9.0, 57, 54, 56),
      _player('ind-11', 'Mohammed Siraj', 'India', 'BOWL', 8.5, 45, 43, 46),
      _player('ind-12', 'Kuldeep Yadav', 'India', 'BOWL', 8.5, 49, 51, 48),
      _player('aus-1', 'David Warner', 'Australia', 'BAT', 9.0, 43, 40, 44),
      _player('aus-2', 'Travis Head', 'Australia', 'BAT', 9.5, 59, 53, 55),
      _player('aus-3', 'Steve Smith', 'Australia', 'BAT', 9.0, 46, 45, 41),
      _player('aus-4', 'Marnus Labuschagne', 'Australia', 'BAT', 8.5, 40, 44, 39),
      _player('aus-5', 'Josh Inglis', 'Australia', 'WK', 8.0, 33, 36, 35),
      _player('aus-6', 'Alex Carey', 'Australia', 'WK', 8.0, 34, 31, 34),
      _player('aus-7', 'Glenn Maxwell', 'Australia', 'AR', 9.5, 52, 50, 47),
      _player('aus-8', 'Marcus Stoinis', 'Australia', 'AR', 8.5, 39, 38, 40),
      _player('aus-9', 'Mitchell Marsh', 'Australia', 'AR', 9.0, 49, 44, 46),
      _player('aus-10', 'Pat Cummins', 'Australia', 'BOWL', 8.5, 41, 40, 43),
      _player('aus-11', 'Mitchell Starc', 'Australia', 'BOWL', 9.0, 53, 49, 52),
      _player('aus-12', 'Adam Zampa', 'Australia', 'BOWL', 8.0, 42, 43, 45),
    ],
    'demo-match-2': [
      _player('csk-1', 'Ruturaj Gaikwad', 'Chennai', 'BAT', 9.5, 60, 59, 55),
      _player('csk-2', 'Devon Conway', 'Chennai', 'BAT', 9.0, 51, 54, 49),
      _player('csk-3', 'Rahul Tripathi', 'Chennai', 'BAT', 8.0, 34, 33, 31),
      _player('csk-4', 'Shivam Dube', 'Chennai', 'BAT', 8.5, 45, 47, 44),
      _player('csk-5', 'MS Dhoni', 'Chennai', 'WK', 8.0, 29, 32, 28),
      _player('csk-6', 'Devon Brevis', 'Chennai', 'WK', 7.5, 26, 28, 27),
      _player('csk-7', 'Ravindra Jadeja', 'Chennai', 'AR', 9.5, 56, 58, 54),
      _player('csk-8', 'Sam Curran', 'Chennai', 'AR', 9.0, 48, 45, 46),
      _player('csk-9', 'Rachin Ravindra', 'Chennai', 'AR', 8.0, 37, 40, 35),
      _player('csk-10', 'Matheesha Pathirana', 'Chennai', 'BOWL', 8.5, 53, 55, 50),
      _player('csk-11', 'Tushar Deshpande', 'Chennai', 'BOWL', 7.5, 35, 37, 34),
      _player('csk-12', 'Maheesh Theekshana', 'Chennai', 'BOWL', 8.0, 41, 43, 40),
      _player('mi-1', 'Rohit Sharma', 'Mumbai', 'BAT', 9.0, 48, 42, 44),
      _player('mi-2', 'Ishan Kishan', 'Mumbai', 'WK', 8.5, 46, 41, 43),
      _player('mi-3', 'Suryakumar Yadav', 'Mumbai', 'BAT', 10.0, 64, 57, 59),
      _player('mi-4', 'Tilak Varma', 'Mumbai', 'BAT', 8.5, 44, 40, 42),
      _player('mi-5', 'Nehal Wadhera', 'Mumbai', 'BAT', 7.5, 28, 27, 26),
      _player('mi-6', 'Hardik Pandya', 'Mumbai', 'AR', 9.5, 52, 47, 49),
      _player('mi-7', 'Tim David', 'Mumbai', 'AR', 8.0, 33, 34, 35),
      _player('mi-8', 'Romario Shepherd', 'Mumbai', 'AR', 8.0, 36, 32, 37),
      _player('mi-9', 'Jasprit Bumrah', 'Mumbai', 'BOWL', 9.0, 62, 58, 57),
      _player('mi-10', 'Gerald Coetzee', 'Mumbai', 'BOWL', 8.5, 46, 43, 41),
      _player('mi-11', 'Piyush Chawla', 'Mumbai', 'BOWL', 7.5, 33, 36, 32),
      _player('mi-12', 'Luke Wood', 'Mumbai', 'BOWL', 7.5, 31, 30, 29),
    ],
  };
}

FantasyPlayer _player(
  String id,
  String name,
  String team,
  String role,
  double credit,
  double last5Avg,
  double venueAvg,
  double opponentAvg,
) {
  return FantasyPlayer(
    id: id,
    name: name,
    team: team,
    role: role,
    credit: credit,
    last5Avg: last5Avg,
    venueAvg: venueAvg,
    opponentAvg: opponentAvg,
  );
}
